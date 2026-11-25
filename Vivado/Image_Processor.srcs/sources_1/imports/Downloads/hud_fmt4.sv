`timescale 1ns / 1ps
// Signed 8-bit value -> 4 ASCII characters, right aligned, e.g. "  -1", " 127", "-128", "   0".
// s = {char0, char1, char2, char3}, char0 is the leftmost.
module hud_fmt4 (
    input  logic signed [7:0] v,
    output logic [31:0]       s
);
    logic       neg;
    logic [7:0] mag, rem;
    logic [7:0] h, t, u;
    logic [7:0] sign;

    always_comb begin
        neg  = v[7];
        mag  = neg ? (~v + 8'd1) : v;          // -128 -> 8'd128
        h    = mag / 8'd100;
        rem  = mag - h * 8'd100;
        t    = rem / 8'd10;
        u    = rem - t * 8'd10;
        sign = neg ? 8'h2D : 8'h20;            // '-' or ' '

        if (h != 0)       s = {sign, 8'h30 + h, 8'h30 + t, 8'h30 + u};
        else if (t != 0)  s = {8'h20, sign, 8'h30 + t, 8'h30 + u};
        else              s = {8'h20, 8'h20, sign, 8'h30 + u};
    end
endmodule
