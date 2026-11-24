#ifndef CONV_CTRL_H
#define CONV_CTRL_H
#include <stdint.h>

/* Programmable 3x3 convolution control (MicroBlaze side).
 * Hardware registers are written through the dual-channel AXI GPIO 'axi_gpio_conv':
 *   channel 1 (offset 0x0) = {addr[11:8], value[7:0]},  channel 2 (offset 0x8) bit 0 = write strobe (toggled)
 */
void conv_init(void);
void conv_load_preset(int n);                                   /* n = 1..9 */
void conv_set_custom(const int8_t k[9], int shift, int bias);   /* preset id becomes 0 = "CUSTOM KERNEL" */
void conv_on_key(uint8_t keycode);                              /* call whenever a new HID keycode arrives */
void conv_uart_poll(void);                                      /* call in the main loop; handles typed commands */

#endif
