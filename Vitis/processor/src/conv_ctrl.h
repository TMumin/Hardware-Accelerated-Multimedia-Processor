#ifndef CONV_CTRL_H
#define CONV_CTRL_H
#include <stdint.h>

/* Programmable 3x3 convolution: keyboard kernel editor (MicroBlaze side).
 *
 *   K                    custom-kernel filter; press again to close the editor
 *   Arrow keys           move the cursor over the 9 kernel cells, SHIFT and BIAS
 *   + / -  (=, - or keypad)   change the selected value by 1
 *   PgUp / PgDn          change it by 10
 *   Backspace            set the selected value to 0
 *   Delete               reset the whole kernel to identity
 *   Esc / Enter          close the editor (the kernel stays active)
 *
 * Hardware registers are written through the dual-channel AXI GPIO 'axi_gpio_conv':
 *   channel 1 (offset 0x0) = {addr[11:8], value[7:0]},  channel 2 (offset 0x8) bit 0 = write strobe (toggled)
 */
void conv_init(void);                                           /* identity kernel, editor closed */
void conv_on_key(uint8_t keycode);                              /* call whenever a new HID keycode arrives */
void conv_uart_poll(void);                                      /* optional: 'k k0..k8 shift bias' typed on the serial terminal */
void conv_set_custom(const int8_t k[9], int shift, int bias);

#endif
