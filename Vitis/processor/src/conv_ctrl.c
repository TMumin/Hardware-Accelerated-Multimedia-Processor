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
#define REG_K(i)      (i)     /* 0..8 */
#define REG_SHIFT     9
#define REG_BIAS      10
#define REG_PRESET    11

static uint32_t strobe = 0;

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

static void write_kernel(const int8_t k[9], int shift, int bias, int preset_id)
{
    for (int i = 0; i < 9; i++) conv_write_reg(REG_K(i), k[i]);
    conv_write_reg(REG_SHIFT, shift);
    conv_write_reg(REG_BIAS, bias);
    conv_write_reg(REG_PRESET, preset_id);
}

/* out = clamp(((sum p_i*k_i) >> shift) + bias, 0, 15), pixels are 4-bit */
typedef struct { const char *name; int8_t k[9]; int shift; int bias; } preset_t;

static const preset_t presets[9] = {
    /* 1 */ { "Identity",       { 0, 0, 0,   0, 1, 0,   0, 0, 0 }, 0, 0 },
    /* 2 */ { "Gaussian 3x3",   { 1, 2, 1,   2, 4, 2,   1, 2, 1 }, 4, 0 },
    /* 3 */ { "Sharpen",        { 0,-1, 0,  -1, 5,-1,   0,-1, 0 }, 0, 0 },
    /* 4 */ { "Emboss",         {-2,-1, 0,  -1, 1, 1,   0, 1, 2 }, 0, 8 },
    /* 5 */ { "Laplacian edge", {-1,-1,-1,  -1, 8,-1,  -1,-1,-1 }, 0, 0 },
    /* 6 */ { "Sobel X",        {-1, 0, 1,  -2, 0, 2,  -1, 0, 1 }, 3, 8 },
    /* 7 */ { "Sobel Y",        {-1,-2,-1,   0, 0, 0,   1, 2, 1 }, 3, 8 },
    /* 8 */ { "Strong blur",    { 7, 7, 7,   7, 7, 7,   7, 7, 7 }, 6, 0 },
    /* 9 */ { "Soft Laplacian", { 0, 1, 0,   1,-4, 1,   0, 1, 0 }, 2, 8 },
};

void conv_init(void)
{
    conv_load_preset(1);
    xil_printf("conv: ready. Keys 1-9 = presets, 0 = custom kernel. UART: 'p N' or 'k k0..k8 shift bias'\r\n");
}

void conv_load_preset(int n)
{
    if (n < 1 || n > 9) return;
    const preset_t *p = &presets[n - 1];
    write_kernel(p->k, p->shift, p->bias, n);
    xil_printf("conv: preset %d (%s)\r\n", n, p->name);
}

void conv_set_custom(const int8_t k[9], int shift, int bias)
{
    write_kernel(k, shift, bias, 0);
    xil_printf("conv: custom kernel loaded (shift %d, bias %d)\r\n", shift, bias);
}

void conv_on_key(uint8_t keycode)
{
    /* HID usage IDs: '1'..'9' = 0x1e..0x26. '0' (0x27) selects the custom kernel and changes nothing. */
    if (keycode >= 0x1e && keycode <= 0x26)
        conv_load_preset(keycode - 0x1e + 1);
}

/* Typed commands on the serial terminal (115200 8N1):
 *   p 3                                  load preset 3
 *   k -1 -1 -1 -1 8 -1 -1 -1 -1 0 0      nine coefficients, shift, bias -> custom kernel
 * then press '0' on the keyboard to view it. */
void conv_uart_poll(void)
{
    static char line[96];
    static int  len = 0;

    while (!XUartLite_IsReceiveEmpty(STDIN_BASEADDRESS)) {
        char c = (char)XUartLite_RecvByte(STDIN_BASEADDRESS);
        if (c == '\r' || c == '\n') {
            line[len] = 0;
            len = 0;
            if (line[0] == 'p') {
                int n;
                if (sscanf(line + 1, "%d", &n) == 1) conv_load_preset(n);
            } else if (line[0] == 'k') {
                int v[11];
                if (sscanf(line + 1, "%d %d %d %d %d %d %d %d %d %d %d",
                           &v[0], &v[1], &v[2], &v[3], &v[4], &v[5], &v[6], &v[7], &v[8], &v[9], &v[10]) == 11) {
                    int8_t k[9];
                    for (int i = 0; i < 9; i++) k[i] = (int8_t)v[i];
                    conv_set_custom(k, v[9] & 0xF, v[10]);
                } else {
                    xil_printf("conv: need 9 coefficients, shift, bias\r\n");
                }
            } else if (line[0] == '?') {
                xil_printf("p N | k k0..k8 shift bias\r\n");
            }
        } else if (len < (int)sizeof(line) - 1) {
            line[len++] = c;
        }
    }
}
