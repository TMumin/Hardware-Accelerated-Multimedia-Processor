`timescale 1ns / 1ps
// Kernel register file written by the MicroBlaze through one dual-channel AXI GPIO (both channels outputs).
//   gpio_data[11:8] = register address, gpio_data[7:0] = value
//   gpio_ctl[0]     = write strobe: software toggles it AFTER writing gpio_data
// Addresses: 0..8 = kernel k0..k8 (signed), 9 = shift, 10 = bias (signed),
//            11 = editor state: value[4] = editor open, value[3:0] = cursor cell (0..10)
// gpio_* come from the MicroBlaze clock domain; data is stable long before the strobe toggles, so a
// 2-flop synchronizer on both is enough. The 25 MHz video clock owns everything after that.
module conv_regs (
    input  logic        clk,            // 25 MHz video clock
    input  logic        rst,            // active high
    input  logic [31:0] gpio_data,
    input  logic [31:0] gpio_ctl,
    output logic [71:0] kernel,
    output logic [3:0]  shift,
    output logic signed [7:0] bias,
    output logic        edit_en,
    output logic [3:0]  cursor
);
    (* ASYNC_REG = "TRUE" *) logic [11:0] data_meta, data_sync;
    (* ASYNC_REG = "TRUE" *) logic        tog_meta, tog_sync;
    logic tog_prev;

    always_ff @(posedge clk) begin
        data_meta <= gpio_data[11:0];
        data_sync <= data_meta;
        tog_meta  <= gpio_ctl[0];
        tog_sync  <= tog_meta;
        tog_prev  <= tog_sync;
    end

    wire        wr   = (tog_sync != tog_prev);
    wire [3:0]  addr = data_sync[11:8];
    wire [7:0]  val  = data_sync[7:0];

    // Power-up state: identity kernel (centre tap = 1), no shift, no bias, editor closed
    localparam logic [71:0] IDENTITY = 72'h00_00_00_00_01_00_00_00_00;

    always_ff @(posedge clk) begin
        if (rst) begin
            kernel  <= IDENTITY;
            shift   <= 4'd0;
            bias    <= 8'sd0;
            edit_en <= 1'b0;
            cursor  <= 4'd4;
        end else if (wr) begin
            if (addr <= 4'd8)  kernel[8*addr +: 8] <= val;
            else if (addr == 4'd9)  shift <= val[3:0];
            else if (addr == 4'd10) bias  <= val;
            else if (addr == 4'd11) begin
                edit_en <= val[4];
                cursor  <= val[3:0];
            end
        end
    end
endmodule
