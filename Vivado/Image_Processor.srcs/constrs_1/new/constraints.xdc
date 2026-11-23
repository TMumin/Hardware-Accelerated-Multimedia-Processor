## Merged constraints for top_level (HDMI video + USB keyboard + DDR3)
## Sources: mb_usb_hdmi_top.xdc, mb_intro_top.xdc (configuration properties only), urbana_ddr3.xdc

## ---- Bitstream / configuration ----
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.Config.SPI_buswidth 4 [current_design]

## ---- 100 MHz board clock (feeds the HDMI clocking wizard) ----
create_clock -period 10.000 -name clk_100 -waveform {0.000 5.000} [get_ports Clk]
set_property -dict {PACKAGE_PIN N15 IOSTANDARD LVCMOS33} [get_ports Clk]

## ---- Reset (BTN0) ----
set_property -dict {PACKAGE_PIN J2 IOSTANDARD LVCMOS25} [get_ports reset_rtl_0]

## ---- UART ----
set_property -dict {PACKAGE_PIN B16 IOSTANDARD LVCMOS33} [get_ports uart_rtl_0_rxd]
set_property -dict {PACKAGE_PIN A16 IOSTANDARD LVCMOS33} [get_ports uart_rtl_0_txd]

## ---- USB host (MAX3421E) ----
set_property -dict {PACKAGE_PIN T13 IOSTANDARD LVCMOS33} [get_ports {gpio_usb_int_tri_i[0]}]
set_property -dict {PACKAGE_PIN V14 IOSTANDARD LVCMOS33} [get_ports usb_spi_sclk]
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports usb_spi_mosi]
set_property -dict {PACKAGE_PIN U12 IOSTANDARD LVCMOS33} [get_ports usb_spi_miso]
set_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS33} [get_ports gpio_usb_rst_tri_o]
set_property -dict {PACKAGE_PIN T12 IOSTANDARD LVCMOS33} [get_ports usb_spi_ss]

## ---- HDMI ----
set_property -dict {PACKAGE_PIN V17 IOSTANDARD TMDS_33} [get_ports hdmi_tmds_clk_n]
set_property -dict {PACKAGE_PIN U16 IOSTANDARD TMDS_33} [get_ports hdmi_tmds_clk_p]
set_property -dict {PACKAGE_PIN U18 IOSTANDARD TMDS_33} [get_ports {hdmi_tmds_data_n[0]}]
set_property -dict {PACKAGE_PIN R17 IOSTANDARD TMDS_33} [get_ports {hdmi_tmds_data_n[1]}]
set_property -dict {PACKAGE_PIN T14 IOSTANDARD TMDS_33} [get_ports {hdmi_tmds_data_n[2]}]
set_property -dict {PACKAGE_PIN U17 IOSTANDARD TMDS_33} [get_ports {hdmi_tmds_data_p[0]}]
set_property -dict {PACKAGE_PIN R16 IOSTANDARD TMDS_33} [get_ports {hdmi_tmds_data_p[1]}]
set_property -dict {PACKAGE_PIN R14 IOSTANDARD TMDS_33} [get_ports {hdmi_tmds_data_p[2]}]

## ---- DDR3 system clock (differential, from the DDR3 reference oscillator) ----
## These two lines were commented out in urbana_ddr3.xdc because the MIG can place the clock itself.
## If implementation reports a conflicting PACKAGE_PIN/IOSTANDARD on SYS_CLK, delete them.
set_property -dict {PACKAGE_PIN C1 IOSTANDARD LVDS_25} [get_ports SYS_CLK_clk_p]
set_property -dict {PACKAGE_PIN B1 IOSTANDARD LVDS_25} [get_ports SYS_CLK_clk_n]

## ---- DDR3 ----
set_property INTERNAL_VREF 0.675 [get_iobanks 34]

# Data
set_property -dict {PACKAGE_PIN K2 IOSTANDARD SSTL135 SLEW FAST IN_TERM UNTUNED_SPLIT_50} [get_ports {ddr3_dq[0]}]
set_property -dict {PACKAGE_PIN M4 IOSTANDARD SSTL135 SLEW FAST IN_TERM UNTUNED_SPLIT_50} [get_ports {ddr3_dq[1]}]
set_property -dict {PACKAGE_PIN K3 IOSTANDARD SSTL135 SLEW FAST IN_TERM UNTUNED_SPLIT_50} [get_ports {ddr3_dq[2]}]
set_property -dict {PACKAGE_PIN L5 IOSTANDARD SSTL135 SLEW FAST IN_TERM UNTUNED_SPLIT_50} [get_ports {ddr3_dq[3]}]
set_property -dict {PACKAGE_PIN L6 IOSTANDARD SSTL135 SLEW FAST IN_TERM UNTUNED_SPLIT_50} [get_ports {ddr3_dq[4]}]
set_property -dict {PACKAGE_PIN M6 IOSTANDARD SSTL135 SLEW FAST IN_TERM UNTUNED_SPLIT_50} [get_ports {ddr3_dq[5]}]
set_property -dict {PACKAGE_PIN L4 IOSTANDARD SSTL135 SLEW FAST IN_TERM UNTUNED_SPLIT_50} [get_ports {ddr3_dq[6]}]
set_property -dict {PACKAGE_PIN K6 IOSTANDARD SSTL135 SLEW FAST IN_TERM UNTUNED_SPLIT_50} [get_ports {ddr3_dq[7]}]
set_property -dict {PACKAGE_PIN N5 IOSTANDARD SSTL135 SLEW FAST IN_TERM UNTUNED_SPLIT_50} [get_ports {ddr3_dq[8]}]
set_property -dict {PACKAGE_PIN M1 IOSTANDARD SSTL135 SLEW FAST IN_TERM UNTUNED_SPLIT_50} [get_ports {ddr3_dq[9]}]
set_property -dict {PACKAGE_PIN P1 IOSTANDARD SSTL135 SLEW FAST IN_TERM UNTUNED_SPLIT_50} [get_ports {ddr3_dq[10]}]
set_property -dict {PACKAGE_PIN N1 IOSTANDARD SSTL135 SLEW FAST IN_TERM UNTUNED_SPLIT_50} [get_ports {ddr3_dq[11]}]
set_property -dict {PACKAGE_PIN R2 IOSTANDARD SSTL135 SLEW FAST IN_TERM UNTUNED_SPLIT_50} [get_ports {ddr3_dq[12]}]
set_property -dict {PACKAGE_PIN N4 IOSTANDARD SSTL135 SLEW FAST IN_TERM UNTUNED_SPLIT_50} [get_ports {ddr3_dq[13]}]
set_property -dict {PACKAGE_PIN P2 IOSTANDARD SSTL135 SLEW FAST IN_TERM UNTUNED_SPLIT_50} [get_ports {ddr3_dq[14]}]
set_property -dict {PACKAGE_PIN M2 IOSTANDARD SSTL135 SLEW FAST IN_TERM UNTUNED_SPLIT_50} [get_ports {ddr3_dq[15]}]

# Address
set_property -dict {PACKAGE_PIN V3 IOSTANDARD SSTL135 SLEW FAST} [get_ports {ddr3_addr[0]}]
set_property -dict {PACKAGE_PIN R4 IOSTANDARD SSTL135 SLEW FAST} [get_ports {ddr3_addr[1]}]
set_property -dict {PACKAGE_PIN P6 IOSTANDARD SSTL135 SLEW FAST} [get_ports {ddr3_addr[2]}]
set_property -dict {PACKAGE_PIN T3 IOSTANDARD SSTL135 SLEW FAST} [get_ports {ddr3_addr[3]}]
set_property -dict {PACKAGE_PIN T6 IOSTANDARD SSTL135 SLEW FAST} [get_ports {ddr3_addr[4]}]
set_property -dict {PACKAGE_PIN T1 IOSTANDARD SSTL135 SLEW FAST} [get_ports {ddr3_addr[5]}]
set_property -dict {PACKAGE_PIN V5 IOSTANDARD SSTL135 SLEW FAST} [get_ports {ddr3_addr[6]}]
set_property -dict {PACKAGE_PIN U7 IOSTANDARD SSTL135 SLEW FAST} [get_ports {ddr3_addr[7]}]
set_property -dict {PACKAGE_PIN R7 IOSTANDARD SSTL135 SLEW FAST} [get_ports {ddr3_addr[8]}]
set_property -dict {PACKAGE_PIN U6 IOSTANDARD SSTL135 SLEW FAST} [get_ports {ddr3_addr[9]}]
set_property -dict {PACKAGE_PIN U3 IOSTANDARD SSTL135 SLEW FAST} [get_ports {ddr3_addr[10]}]
set_property -dict {PACKAGE_PIN P5 IOSTANDARD SSTL135 SLEW FAST} [get_ports {ddr3_addr[11]}]
set_property -dict {PACKAGE_PIN V6 IOSTANDARD SSTL135 SLEW FAST} [get_ports {ddr3_addr[12]}]

# Bank address and command
set_property -dict {PACKAGE_PIN V2 IOSTANDARD SSTL135 SLEW FAST} [get_ports {ddr3_ba[0]}]
set_property -dict {PACKAGE_PIN V4 IOSTANDARD SSTL135 SLEW FAST} [get_ports {ddr3_ba[1]}]
set_property -dict {PACKAGE_PIN R3 IOSTANDARD SSTL135 SLEW FAST} [get_ports {ddr3_ba[2]}]
set_property -dict {PACKAGE_PIN U2 IOSTANDARD SSTL135 SLEW FAST} [get_ports ddr3_ras_n]
set_property -dict {PACKAGE_PIN U1 IOSTANDARD SSTL135 SLEW FAST} [get_ports ddr3_cas_n]
set_property -dict {PACKAGE_PIN T2 IOSTANDARD SSTL135 SLEW FAST} [get_ports ddr3_we_n]
set_property -dict {PACKAGE_PIN M5 IOSTANDARD SSTL135 SLEW FAST} [get_ports ddr3_reset_n]
set_property -dict {PACKAGE_PIN T5 IOSTANDARD SSTL135 SLEW FAST} [get_ports {ddr3_cke[0]}]
set_property -dict {PACKAGE_PIN P7 IOSTANDARD SSTL135 SLEW FAST} [get_ports {ddr3_odt[0]}]

# Data masks
set_property -dict {PACKAGE_PIN K4 IOSTANDARD SSTL135 SLEW FAST} [get_ports {ddr3_dm[0]}]
set_property -dict {PACKAGE_PIN M3 IOSTANDARD SSTL135 SLEW FAST} [get_ports {ddr3_dm[1]}]

# Data strobes
set_property -dict {PACKAGE_PIN K1 IOSTANDARD DIFF_SSTL135 SLEW FAST IN_TERM UNTUNED_SPLIT_50} [get_ports {ddr3_dqs_p[0]}]
set_property -dict {PACKAGE_PIN L1 IOSTANDARD DIFF_SSTL135 SLEW FAST IN_TERM UNTUNED_SPLIT_50} [get_ports {ddr3_dqs_n[0]}]
set_property -dict {PACKAGE_PIN N3 IOSTANDARD DIFF_SSTL135 SLEW FAST IN_TERM UNTUNED_SPLIT_50} [get_ports {ddr3_dqs_p[1]}]
set_property -dict {PACKAGE_PIN N2 IOSTANDARD DIFF_SSTL135 SLEW FAST IN_TERM UNTUNED_SPLIT_50} [get_ports {ddr3_dqs_n[1]}]

# DDR3 clock
set_property -dict {PACKAGE_PIN R5 IOSTANDARD DIFF_SSTL135 SLEW FAST} [get_ports {ddr3_ck_p[0]}]
set_property -dict {PACKAGE_PIN T4 IOSTANDARD DIFF_SSTL135 SLEW FAST} [get_ports {ddr3_ck_n[0]}]

## ---- Clock domain crossing ----
## MicroBlaze keycode (MIG ui_clk, 83.33 MHz) -> 25 MHz video clock. The two clocks come from different
## sources, so this is an asynchronous crossing handled by the 2-flop synchronizer in top_level.
set_false_path -to [get_cells {keycode_meta_reg[*]}]

## ---- OV7670 camera on Pmod A + Pmod B (3.3 V) ----
## Power and ground are NOT constrained: they are fixed pins on the Pmod connectors
## (pins 6 and 12 = VCC, pins 5 and 11 = GND). Use those for the camera's 3V3/GND/RESET/PWDN wiring.
## Pmod A: camera data D0..D7. Connector pins 1-4 = F14 F15 H13 H14 (D0-D3), pins 7-10 = J13 J14 E14 E15 (D4-D7)
set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33} [get_ports {cam_d[0]}]
set_property -dict {PACKAGE_PIN F15 IOSTANDARD LVCMOS33} [get_ports {cam_d[1]}]
set_property -dict {PACKAGE_PIN H13 IOSTANDARD LVCMOS33} [get_ports {cam_d[2]}]
set_property -dict {PACKAGE_PIN H14 IOSTANDARD LVCMOS33} [get_ports {cam_d[3]}]
set_property -dict {PACKAGE_PIN J13 IOSTANDARD LVCMOS33} [get_ports {cam_d[4]}]
set_property -dict {PACKAGE_PIN J14 IOSTANDARD LVCMOS33} [get_ports {cam_d[5]}]
set_property -dict {PACKAGE_PIN E14 IOSTANDARD LVCMOS33} [get_ports {cam_d[6]}]
set_property -dict {PACKAGE_PIN E15 IOSTANDARD LVCMOS33} [get_ports {cam_d[7]}]
## Pmod B: control and clocks. Connector pins 1-4 = H18 G18 K14 J15, pins 7-8 = H16 H17
set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVCMOS33} [get_ports cam_pclk]    ;# Pmod B pin 1
set_property -dict {PACKAGE_PIN G18 IOSTANDARD LVCMOS33} [get_ports cam_vsync]   ;# Pmod B pin 2
set_property -dict {PACKAGE_PIN K14 IOSTANDARD LVCMOS33} [get_ports cam_href]    ;# Pmod B pin 3
set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports cam_xclk]  ;# Pmod B pin 4
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33 PULLUP TRUE} [get_ports cam_sioc] ;# Pmod B pin 7
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33 PULLUP TRUE} [get_ports cam_siod] ;# Pmod B pin 8

## Camera pixel clock (XCLK = 25 MHz -> PCLK = 25 MHz with CLKRC = 0)
create_clock -period 40.000 -name cam_pclk [get_ports cam_pclk]
## Only if Place Design errors that PCLK is not on a clock-capable pin, uncomment:
# set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets cam_pclk_IBUF]
