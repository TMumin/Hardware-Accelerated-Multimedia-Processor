`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2026 10:23:59 PM
// Design Name: 
// Module Name: line_buffer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module line_buffer(
        input logic clk, we,
        input logic [9:0] waddr, raddr,
        input logic [3:0] din,
        output logic [3:0] dout
    );
    
    (* ram_style = "distributed" *) logic [3:0] mem [640];
    
    always_ff @(posedge clk) begin
        if (we) begin
            mem[waddr] <= din;
            dout <= mem[raddr];
        end
    end
    
endmodule
