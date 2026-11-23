`timescale 1ns / 1ps
// Module Name: top_level

module top_level(
    input logic Clk,                    // 100 MHz board clock, used by clk_wiz for HDMI
    input logic reset_rtl_0,

    //MIG differential system clock
    input  logic SYS_CLK_clk_n,
    input  logic SYS_CLK_clk_p,

    //DDR3
    output logic [12:0] ddr3_addr,
    output logic [2:0]  ddr3_ba,
    output logic        ddr3_cas_n,
    output logic [0:0]  ddr3_ck_n,
    output logic [0:0]  ddr3_ck_p,
    output logic [0:0]  ddr3_cke,
    output logic [1:0]  ddr3_dm,
    inout  wire  [15:0] ddr3_dq,
    inout  wire  [1:0]  ddr3_dqs_n,
    inout  wire  [1:0]  ddr3_dqs_p,
    output logic [0:0]  ddr3_odt,
    output logic        ddr3_ras_n,
    output logic        ddr3_reset_n,
    output logic        ddr3_we_n,

    //USB signals
    input logic [0:0] gpio_usb_int_tri_i,
    output logic gpio_usb_rst_tri_o,
    input logic usb_spi_miso,
    output logic usb_spi_mosi,
    output logic usb_spi_sclk,
    output logic usb_spi_ss,
    
    //UART
    input logic uart_rtl_0_rxd,
    output logic uart_rtl_0_txd,
    
    //HDMI
    output logic hdmi_tmds_clk_n,
    output logic hdmi_tmds_clk_p,
    output logic [2:0]hdmi_tmds_data_n,
    output logic [2:0]hdmi_tmds_data_p
    );
    
    logic [31:0] keycode0_gpio, keycode1_gpio;  // keycode1_gpio unused
    logic clk_25MHz, clk_125MHz;
    logic locked;
    logic [9:0] drawX, drawY;

    logic hsync, vsync, vde;
    logic [3:0] red_raw, green_raw, blue_raw;
    logic reset_ah;
    
    logic hsync_1, vsync_1, vde_1, hsync_2, vsync_2, vde_2;
    logic [9:0] drawX_d, drawY_d;
    logic [3:0] red_filtered, green_filtered, blue_filtered;
    
    assign reset_ah = reset_rtl_0;
    
    always_ff @ (posedge clk_25MHz) begin
        hsync_1 <= hsync;
        vsync_1 <= vsync;
        vde_1 <= vde;
        hsync_2 <= hsync_1;
        vsync_2 <= vsync_1;
        vde_2 <= vde_1;
        drawX_d <= drawX;
        drawY_d <= drawY;
    end
    
    //To prevent trailing window
    logic [9:0]  drawX_n, drawY_n;
    logic [16:0] addr_w;
    logic [11:0] pix_w;
    
    assign drawX_n = (drawX == 10'd639) ? 10'd639 : drawX + 10'd1;
    assign drawY_n = (drawY == 10'd479) ? 10'd479 : drawY + 10'd1;
    assign addr_w  = drawY_n[9:1] * 320 + drawX_n[9:1];
    
    mb_block mb_block_i (
        .SYS_CLK_clk_n(SYS_CLK_clk_n),
        .SYS_CLK_clk_p(SYS_CLK_clk_p),
        .ddr3_addr(ddr3_addr),
        .ddr3_ba(ddr3_ba),
        .ddr3_cas_n(ddr3_cas_n),
        .ddr3_ck_n(ddr3_ck_n),
        .ddr3_ck_p(ddr3_ck_p),
        .ddr3_cke(ddr3_cke),
        .ddr3_dm(ddr3_dm),
        .ddr3_dq(ddr3_dq),
        .ddr3_dqs_n(ddr3_dqs_n),
        .ddr3_dqs_p(ddr3_dqs_p),
        .ddr3_odt(ddr3_odt),
        .ddr3_ras_n(ddr3_ras_n),
        .ddr3_reset_n(ddr3_reset_n),
        .ddr3_we_n(ddr3_we_n),
        .gpio_usb_int_tri_i(gpio_usb_int_tri_i),
        .gpio_usb_keycode_0_tri_o(keycode0_gpio),
        .gpio_usb_keycode_1_tri_i(32'b0),
        .gpio_usb_keycode_1_tri_o(keycode1_gpio),
        .gpio_usb_keycode_1_tri_t(),
        .gpio_usb_rst_tri_o(gpio_usb_rst_tri_o),
        .reset_rtl_0(~reset_ah), //Block designs expect active low reset, all other modules are active high
        .uart_rxd(uart_rtl_0_rxd),
        .uart_txd(uart_rtl_0_txd),
        .usb_spi_miso(usb_spi_miso),
        .usb_spi_mosi(usb_spi_mosi),
        .usb_spi_sclk(usb_spi_sclk),
        .usb_spi_ss(usb_spi_ss)
    );
        
    //clock wizard configured with a 1x and 5x clock for HDMI
    clk_wiz_0 clk_wiz (
        .clk_out1(clk_25MHz),
        .clk_out2(clk_125MHz),
        .reset(reset_ah),
        .locked(locked),
        .clk_in1(Clk)
    );
    
    //VGA Sync signal generator
    vga_controller vga (
        .pixel_clk(clk_25MHz),
        .reset(reset_ah),
        .hs(hsync),
        .vs(vsync),
        .active_nblank(vde),
        .drawX(drawX),
        .drawY(drawY)
    );    

    //Real Digital VGA to HDMI converter
    hdmi_tx_0 vga_to_hdmi (
    
        //Clocking and Reset
        .pix_clk(clk_25MHz),
        .pix_clkx5(clk_125MHz),
        .pix_clk_locked(locked),
        .rst(reset_ah),
        
        //Color and Sync Signals
        .red(red_filtered),
        .green(green_filtered),
        .blue(blue_filtered),
        .hsync(hsync_2),
        .vsync(vsync_2),
        .vde(vde_2),
        
        //aux Data (unused)
        .aux0_din(4'b0),
        .aux1_din(4'b0),
        .aux2_din(4'b0),
        .ade(1'b0),
        
        //Differential outputs
        .TMDS_CLK_P(hdmi_tmds_clk_p),          
        .TMDS_CLK_N(hdmi_tmds_clk_n),          
        .TMDS_DATA_P(hdmi_tmds_data_p),         
        .TMDS_DATA_N(hdmi_tmds_data_n)          
    );
    
    logic [16:0] addr;
    logic [11:0] pix, pix_d;
    
    always_ff @ (posedge clk_25MHz) begin
        pix_d <= pix;
    end

    assign addr = drawY[9:1] * 320 + drawX[9:1];
    
    assign red_raw = pix_d[11:8];
    assign green_raw = pix_d[7:4];
    assign blue_raw = pix_d[3:0];
    
    //Image Rom Module
    image_rom image_rom_i(
        .clk(clk_25MHz),
        .addr(addr),
        .data(pix),
        .addr_w(addr_w),
        .data_w(pix_w)
    );
    
    logic [3:0] gray;
    
    //Grayscale Module for regular filter
    grayscale grayscale_i(
        .r(red_raw),
        .g(green_raw),
        .b(blue_raw),
        .z(gray)
    );
    
    logic [3:0] gray_d;
    
    //Grayscale Module for Window Generator 
    grayscale grayscale_w_i(
        .r(pix_w[11:8]),
        .g(pix_w[7:4]),
        .b(pix_w[3:0]),
        .z(gray_d)
    );
    
    logic [3:0] p0_s, p1_s, p2_s, p3_s, p4_s, p5_s, p6_s, p7_s, p8_s;
    
    //Window Generator Module
    window_generator window_generator_i(
        .clk(clk_25MHz),
        .rst(reset_ah),
        .en(vde_1),
        .din(gray_d),
        .p0(p0_s),
        .p1(p1_s),
        .p2(p2_s),
        .p3(p3_s),
        .p4(p4_s),
        .p5(p5_s),
        .p6(p6_s),
        .p7(p7_s),
        .p8(p8_s)
    );
    
    logic edge_out;
    
    //Sobel Module
    sobel sobel_i(
        .p0(p0_s),
        .p1(p1_s),
        .p2(p2_s),
        .p3(p3_s),
        .p4(p4_s),
        .p5(p5_s),
        .p6(p6_s),
        .p7(p7_s),
        .p8(p8_s),
        .edge_out(edge_out)
    );
    
    logic border;
    logic edge_actual;
    logic [3:0] sobel_color;
    
    //Final edge processing for Sobel
    always_ff @(posedge clk_25MHz) begin
        border <= (drawX_d < 2) || (drawY_d < 2);
    end
    
    assign edge_actual = border ? 0 : edge_out;
    assign sobel_color = edge_actual ? 4'hf : 4'h0;
    
    //RGB Gaussian
    logic [3:0] p0_r, p1_r, p2_r, p3_r, p4_r, p5_r, p6_r, p7_r, p8_r;
    logic [3:0] p0_g, p1_g, p2_g, p3_g, p4_g, p5_g, p6_g, p7_g, p8_g;
    logic [3:0] p0_b, p1_b, p2_b, p3_b, p4_b, p5_b, p6_b, p7_b, p8_b;
    
    window_generator window_generator_r(
        .clk(clk_25MHz),
        .rst(reset_ah),
        .en(vde_1),
        .din(pix_w[11:8]),
        .p0(p0_r),
        .p1(p1_r),
        .p2(p2_r),
        .p3(p3_r),
        .p4(p4_r),
        .p5(p5_r),
        .p6(p6_r),
        .p7(p7_r),
        .p8(p8_r)
    );
    window_generator window_generator_g(
        .clk(clk_25MHz),
        .rst(reset_ah),
        .en(vde_1),
        .din(pix_w[7:4]),
        .p0(p0_g),
        .p1(p1_g),
        .p2(p2_g),
        .p3(p3_g),
        .p4(p4_g),
        .p5(p5_g),
        .p6(p6_g),
        .p7(p7_g),
        .p8(p8_g)
    );
    window_generator window_generator_b(
        .clk(clk_25MHz),
        .rst(reset_ah),
        .en(vde_1),
        .din(pix_w[3:0]),
        .p0(p0_b),
        .p1(p1_b),
        .p2(p2_b),
        .p3(p3_b),
        .p4(p4_b),
        .p5(p5_b),
        .p6(p6_b),
        .p7(p7_b),
        .p8(p8_b)
    );
    
    logic [3:0] red_blur, green_blur, blue_blur;
    
    gaussian gaussian_r(
        .p0(p0_r),
        .p1(p1_r),
        .p2(p2_r),
        .p3(p3_r),
        .p4(p4_r),
        .p5(p5_r),
        .p6(p6_r),
        .p7(p7_r),
        .p8(p8_r),
        .weight(red_blur)
    );
    gaussian gaussian_g(
        .p0(p0_g),
        .p1(p1_g),
        .p2(p2_g),
        .p3(p3_g),
        .p4(p4_g),
        .p5(p5_g),
        .p6(p6_g),
        .p7(p7_g),
        .p8(p8_g),
        .weight(green_blur)
    );
    gaussian gaussian_b(
        .p0(p0_b),
        .p1(p1_b),
        .p2(p2_b),
        .p3(p3_b),
        .p4(p4_b),
        .p5(p5_b),
        .p6(p6_b),
        .p7(p7_b),
        .p8(p8_b),
        .weight(blue_blur)
    );
    
    //Sharpen    
    logic [3:0] red_sharp, green_sharp, blue_sharp;
    
    sharpen sharpen_r(
        .p0(p0_r),
        .p1(p1_r),
        .p2(p2_r),
        .p3(p3_r),
        .p4(p4_r),
        .p5(p5_r),
        .p6(p6_r),
        .p7(p7_r),
        .p8(p8_r),
        .weight(red_sharp)
    );
    sharpen sharpen_g(
        .p0(p0_g),
        .p1(p1_g),
        .p2(p2_g),
        .p3(p3_g),
        .p4(p4_g),
        .p5(p5_g),
        .p6(p6_g),
        .p7(p7_g),
        .p8(p8_g),
        .weight(green_sharp)
    );
    sharpen sharpen_b(
        .p0(p0_b),
        .p1(p1_b),
        .p2(p2_b),
        .p3(p3_b),
        .p4(p4_b),
        .p5(p5_b),
        .p6(p6_b),
        .p7(p7_b),
        .p8(p8_b),
        .weight(blue_sharp)
    );
    
    //Emboss    
    logic [3:0] gray_emboss;
    
    emboss emboss_i(
        .p0(p0_s),
        .p1(p1_s),
        .p2(p2_s),
        .p3(p3_s),
        .p4(p4_s),
        .p5(p5_s),
        .p6(p6_s),
        .p7(p7_s),
        .p8(p8_s),
        .weight(gray_emboss)
    );
    
    //RGB Emboss    
    logic [3:0] red_emboss, green_emboss, blue_emboss;
    
    emboss emboss_r(
        .p0(p0_r),
        .p1(p1_r),
        .p2(p2_r),
        .p3(p3_r),
        .p4(p4_r),
        .p5(p5_r),
        .p6(p6_r),
        .p7(p7_r),
        .p8(p8_r),
        .weight(red_emboss)
    );
    emboss emboss_g(
        .p0(p0_g),
        .p1(p1_g),
        .p2(p2_g),
        .p3(p3_g),
        .p4(p4_g),
        .p5(p5_g),
        .p6(p6_g),
        .p7(p7_g),
        .p8(p8_g),
        .weight(green_emboss)
    );
    emboss emboss_b(
        .p0(p0_b),
        .p1(p1_b),
        .p2(p2_b),
        .p3(p3_b),
        .p4(p4_b),
        .p5(p5_b),
        .p6(p6_b),
        .p7(p7_b),
        .p8(p8_b),
        .weight(blue_emboss)
    );
    
    //Filter selection MUX
    logic [7:0] keycode, keycode_meta, keycode_last;
    
    always_comb begin
        unique case (keycode_last)
            8'h14: {red_filtered, green_filtered, blue_filtered} = {red_raw, green_raw, blue_raw};
            8'h1a: {red_filtered, green_filtered, blue_filtered} = {gray, gray, gray};
            8'h08: {red_filtered, green_filtered, blue_filtered} = {~red_raw, ~green_raw, ~blue_raw};
            8'h15: {red_filtered, green_filtered, blue_filtered} = {red_raw, 4'h0, 4'h0};
            8'h17: {red_filtered, green_filtered, blue_filtered} = {4'h0, green_raw, 4'h0};
            8'h1c: {red_filtered, green_filtered, blue_filtered} = {4'h0, 4'h0, blue_raw};
            8'h18: {red_filtered, green_filtered, blue_filtered} = {sobel_color, sobel_color, sobel_color};
            8'h0c: {red_filtered, green_filtered, blue_filtered} = border ? {red_raw, green_raw, blue_raw} : {red_blur, green_blur, blue_blur};
            8'h12: {red_filtered, green_filtered, blue_filtered} = border ? {red_raw, green_raw, blue_raw} : {red_sharp, green_sharp, blue_sharp};
            8'h13: {red_filtered, green_filtered, blue_filtered} = border ? {gray, gray, gray} : {gray_emboss, gray_emboss, gray_emboss};
            8'h2f: {red_filtered, green_filtered, blue_filtered} = border ? {red_raw, green_raw, blue_raw} : {red_emboss, green_emboss, blue_emboss};
            default: {red_filtered, green_filtered, blue_filtered} = {red_raw, green_raw, blue_raw};
        endcase
    end
    
    always_ff @(posedge clk_25MHz) begin
        keycode_meta <= keycode0_gpio[7:0];
        keycode <= keycode_meta;
    
        if (reset_ah)
            keycode_last <= 8'h14;
        else if (keycode == 8'h14 || keycode == 8'h1a || keycode == 8'h08 || 
                 keycode == 8'h15 || keycode == 8'h17 || keycode == 8'h1c ||
                 keycode == 8'h18 || keycode == 8'h0c || keycode == 8'h12 ||
                 keycode == 8'h13 || keycode == 8'h2f)
            keycode_last <= keycode;
    end
    
endmodule