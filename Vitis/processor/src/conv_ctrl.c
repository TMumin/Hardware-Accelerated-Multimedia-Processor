#include <stdio.h>
#include <string.h>
#include "xil_io.h"
#include "xparameters.h"
#include "xuartlite_l.h"
#include "conv_ctrl.h"

/* Base address of the conv GPIO. The macro name follows the IP instance name in the block design;
 * if your instance is called axi_gpio_conv it is XPAR_AXI_GPIO_CONV_BASEADDR (some tool versions use
 * XPAR_AXI_GPIO_CONV_S_AXI_BASEADDR). Change this one line if the compiler cannot find it. */
#ifndef CONV_GPIO_BASE
#define CONV_GPIO_BASE XPAR_AXI_GPIO_CONV_BASEADDR
#endif
#define GPIO_DATA   (CONV_GPIO_BASE + 0x0)
#define GPIO2_DATA  (CONV_GPIO_BASE + 0x8)

/* Register addresses (must match conv_regs.sv) */
#define REG_SHIFT   9
#define REG_BIAS    10
#define REG_EDITOR  11      /* value[4] = editor open, value[3:0] = cursor field */

/* Fields the cursor can sit on: 0..8 = kernel cells (row-major), 9 = SHIFT, 10 = BIAS */
#define FIELD_SHIFT 9
#define FIELD_BIAS  10

/* USB HID usage IDs */
#define KEY_K        0x0e
#define KEY_ENTER    0x28
#define KEY_ESC      0x29
#define KEY_BKSP     0x2a
#define KEY_MINUS    0x2d
#define KEY_EQUAL    0x2e      /* '+' is shift + '=' */
#define KEY_PGUP     0x4b
#define KEY_DELETE   0x4c
#define KEY_PGDN     0x4e
#define KEY_RIGHT    0x4f
#define KEY_LEFT     0x50
#define KEY_DOWN     0x51
#define KEY_UP       0x52
#define KEY_KP_MINUS 0x56
#define KEY_KP_PLUS  0x57

static uint32_t strobe = 0;
static int8_t   kern[9] = { 0, 0, 0, 0, 1, 0, 0, 0, 0 };   /* software copy: the hardware registers are write-only */
static int      shift_v = 0;
static int      bias_v  = 0;
static int      cursor  = 4;
static int      editing = 0;

static void settle(void)
{   /* give the 25 MHz domain time to see the strobe before the next data word (about 1-2 us) */
    for (volatile int i = 0; i < 200; i++) { }
}

static void conv_write_reg(int addr, int val)
{
    Xil_Out32(GPIO_DATA, ((uint32_t)(addr & 0xF) << 8) | ((uint32_t)val & 0xFF));
    settle();                       /* data must be stable before the strobe crosses clock domains */
    strobe ^= 1u;
    Xil_Out32(GPIO2_DATA, strobe);
    settle();
}

static int clampi(int v, int lo, int hi) { return v < lo ? lo : (v > hi ? hi : v); }

static int get_field(int f)
{
    if (f == FIELD_SHIFT) return shift_v;
    if (f == FIELD_BIAS)  return bias_v;
    return kern[f];
}

static void set_field(int f, int v)
{
    if (f == FIELD_SHIFT) {
        shift_v = clampi(v, 0, 15);
        conv_write_reg(REG_SHIFT, shift_v);
    } else if (f == FIELD_BIAS) {
        bias_v = clampi(v, -128, 127);
        conv_write_reg(REG_BIAS, bias_v);
    } else {
        kern[f] = (int8_t)clampi(v, -128, 127);
        conv_write_reg(f, kern[f]);
    }
}

static void write_all(void)
{
    for (int i = 0; i < 9; i++) conv_write_reg(i, kern[i]);
    conv_write_reg(REG_SHIFT, shift_v);
    conv_write_reg(REG_BIAS, bias_v);
}

static void push_editor(void)
{
    conv_write_reg(REG_EDITOR, (editing ? 0x10 : 0x00) | (cursor & 0xF));
}

static void reset_identity(void)
{
    static const int8_t id[9] = { 0, 0, 0, 0, 1, 0, 0, 0, 0 };
    memcpy(kern, id, sizeof(kern));
    shift_v = 0;
    bias_v  = 0;
    write_all();
}

void conv_init(void)
{
    editing = 0;
    cursor  = 4;
    reset_identity();
    push_editor();
    xil_printf("conv: ready. K = kernel editor, arrows move, +/- change, Esc closes\r\n");
}

void conv_set_custom(const int8_t k[9], int shift, int bias)
{
    memcpy(kern, k, sizeof(kern));
    shift_v = clampi(shift, 0, 15);
    bias_v  = clampi(bias, -128, 127);
    write_all();
}

static int is_filter_key(uint8_t kc)
{   /* the other hardware filter keys: Q W E R T Y U I O P [ ] */
    switch (kc) {
    case 0x14: case 0x1a: case 0x08: case 0x15: case 0x17: case 0x1c:
    case 0x18: case 0x0c: case 0x12: case 0x13: case 0x2f: case 0x30:
        return 1;
    default:
        return 0;
    }
}

static void move_cursor(uint8_t kc)
{
    int c = cursor;
    switch (kc) {
    case KEY_RIGHT: if (c < FIELD_BIAS) c++;                  break;
    case KEY_LEFT:  if (c > 0) c--;                           break;
    case KEY_DOWN:  if (c <= 5)       c += 3;
                    else if (c <= 8)  c = FIELD_SHIFT;        /* bottom kernel row -> SHIFT */
                    else if (c == FIELD_SHIFT) c = FIELD_BIAS;
                    break;
    case KEY_UP:    if (c >= 3 && c <= 8) c -= 3;
                    else if (c == FIELD_SHIFT) c = 7;         /* back up to the middle column */
                    else if (c == FIELD_BIAS)  c = FIELD_SHIFT;
                    break;
    }
    if (c != cursor) { cursor = c; push_editor(); }
}

void conv_on_key(uint8_t keycode)
{
    if (keycode == 0) return;                      /* key release */

    if (keycode == KEY_K) {                        /* K: custom-kernel filter, toggles the editor */
        editing = !editing;
        push_editor();
        xil_printf("conv: editor %s\r\n", editing ? "open" : "closed");
        return;
    }

    if (!editing) return;

    switch (keycode) {
    case KEY_RIGHT: case KEY_LEFT: case KEY_DOWN: case KEY_UP:
        move_cursor(keycode);
        break;
    case KEY_EQUAL: case KEY_KP_PLUS:   set_field(cursor, get_field(cursor) + 1);  break;
    case KEY_MINUS: case KEY_KP_MINUS:  set_field(cursor, get_field(cursor) - 1);  break;
    case KEY_PGUP:                      set_field(cursor, get_field(cursor) + 10); break;
    case KEY_PGDN:                      set_field(cursor, get_field(cursor) - 10); break;
    case KEY_BKSP:                      set_field(cursor, 0);                      break;
    case KEY_DELETE:                    reset_identity();                          break;
    case KEY_ESC: case KEY_ENTER:
        editing = 0;
        push_editor();
        xil_printf("conv: editor closed\r\n");
        break;
    default:
        if (is_filter_key(keycode)) {              /* another filter was selected: close the editor */
            editing = 0;
            push_editor();
        }
        break;
    }
}

/* Optional typed command on the serial terminal (115200 8N1):
 *   k -1 -1 -1 -1 8 -1 -1 -1 -1 0 0      nine coefficients, shift, bias
 * then press K to see it. */
void conv_uart_poll(void)
{
    static char line[96];
    static int  len = 0;

    while (!XUartLite_IsReceiveEmpty(STDIN_BASEADDRESS)) {
        char c = (char)XUartLite_RecvByte(STDIN_BASEADDRESS);
        if (c == '\r' || c == '\n') {
            line[len] = 0;
            len = 0;
            if (line[0] == 'k') {
                int v[11];
                if (sscanf(line + 1, "%d %d %d %d %d %d %d %d %d %d %d",
                           &v[0], &v[1], &v[2], &v[3], &v[4], &v[5], &v[6], &v[7], &v[8], &v[9], &v[10]) == 11) {
                    int8_t k[9];
                    for (int i = 0; i < 9; i++) k[i] = (int8_t)clampi(v[i], -128, 127);
                    conv_set_custom(k, v[9], v[10]);
                    xil_printf("conv: custom kernel loaded\r\n");
                } else {
                    xil_printf("conv: need 9 coefficients, shift, bias\r\n");
                }
            }
        } else if (len < (int)sizeof(line) - 1) {
            line[len++] = c;
        }
    }
}
