`timescale 1ns / 1ps
// Programmable 3x3 convolution on one 4-bit channel.
//   out = clamp( ((sum_i p_i * k_i) >>> shift) + bias , 0 , 15 )
// p_i: 4-bit unsigned window pixels (same p0..p8 order as window_generator), k_i: signed 8-bit.
// Purely combinational so it drops into the same pipeline slot as gaussian/sharpen/emboss.
module conv_engine (
    input  logic [3:0]        p0, p1, p2, p3, p4, p5, p6, p7, p8,
    input  logic [71:0]       kernel,   // k_i = kernel[8*i +: 8], signed
    input  logic [3:0]        shift,    // arithmetic right shift applied to the sum
    input  logic signed [7:0] bias,     // added after the shift
    output logic [3:0]        out
);
    logic [3:0]         pp [0:8];
    logic signed [7:0]  kk [0:8];
    logic signed [15:0] sum, scaled, total;

    always_comb begin
        pp[0] = p0; pp[1] = p1; pp[2] = p2;
        pp[3] = p3; pp[4] = p4; pp[5] = p5;
        pp[6] = p6; pp[7] = p7; pp[8] = p8;

        sum = '0;
        for (int i = 0; i < 9; i++) begin
            kk[i] = kernel[8*i +: 8];
            sum   = sum + $signed({1'b0, pp[i]}) * kk[i];   // |sum| <= 9*15*128 fits in 16 bits
        end

        scaled = sum >>> shift;
        total  = scaled + bias;

        if (total < 0)        out = 4'd0;
        else if (total > 15)  out = 4'd15;
        else                  out = total[3:0];
    end
endmodule
