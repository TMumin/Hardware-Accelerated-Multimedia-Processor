`timescale 1ns / 1ps
// On-screen display: two lines of 8x16 text in the top-left corner.
//   line 0:  FILTER: <name>        line 1:  FRAME:  <6-digit frame count>
// Inputs drawX_d/drawY_d must be the pixel coordinates aligned with the output pixel (t=2 in top_level).
// Outputs are combinational from those coordinates: `box` = inside the dimmed background panel,
// `text` = this pixel is a lit glyph pixel.
module hud #(
    parameter int X0 = 16,
    parameter int Y0 = 16
)(
    input  logic       clk,         // 25 MHz
    input  logic       rst,
    input  logic       frame_pulse, // high during vertical sync (any polarity; rising edge counts a frame)
    input  logic [9:0] drawX_d,
    input  logic [9:0] drawY_d,
    input  logic [4:0] name_idx,
    output logic       box,
    output logic       text
);
    localparam int COLS = 24;
    localparam int W = COLS * 8;    // 192
    localparam int H = 32;          // two 16-row lines

    // ---------------- frame counter (6-digit BCD) ----------------
    logic        fp_q;
    logic [23:0] bcd, bcd_next;
    logic        c;
    logic [3:0]  nd;
    always_comb begin
        c = 1'b1;
        for (int i = 0; i < 6; i++) begin
            nd = bcd[4*i +: 4] + {3'b000, c};
            if (nd == 4'd10) begin nd = 4'd0; c = 1'b1; end else c = 1'b0;
            bcd_next[4*i +: 4] = nd;
        end
    end
    always_ff @(posedge clk) begin
        fp_q <= frame_pulse;
        if (rst)                         bcd <= '0;
        else if (frame_pulse && !fp_q)   bcd <= bcd_next;
    end

    // ---------------- filter names (16 chars each, space padded) ----------------
    function automatic logic [127:0] name_of(input logic [4:0] i);
        case (i)
            5'd0:  name_of = "RAW             ";
            5'd1:  name_of = "GRAYSCALE       ";
            5'd2:  name_of = "INVERT          ";
            5'd3:  name_of = "RED ONLY        ";
            5'd4:  name_of = "GREEN ONLY      ";
            5'd5:  name_of = "BLUE ONLY       ";
            5'd6:  name_of = "SOBEL EDGES     ";
            5'd7:  name_of = "GAUSSIAN BLUR   ";
            5'd8:  name_of = "SHARPEN         ";
            5'd9:  name_of = "EMBOSS GRAY     ";
            5'd10: name_of = "EMBOSS COLOR    ";
            5'd11: name_of = "CUSTOM KERNEL   ";
            5'd12: name_of = "K1 IDENTITY     ";
            5'd13: name_of = "K2 GAUSSIAN 3X3 ";
            5'd14: name_of = "K3 SHARPEN      ";
            5'd15: name_of = "K4 EMBOSS       ";
            5'd16: name_of = "K5 LAPLACIAN    ";
            5'd17: name_of = "K6 SOBEL X      ";
            5'd18: name_of = "K7 SOBEL Y      ";
            5'd19: name_of = "K8 STRONG BLUR  ";
            5'd20: name_of = "K9 SOFT LAPLACE ";
            default: name_of = "                ";
        endcase
    endfunction

    // ---------------- character / glyph lookup ----------------
    localparam logic [9:0] X0_L = X0;
    localparam logic [9:0] Y0_L = Y0;
    logic [9:0] dx, dy;
    logic [4:0] nc;
    logic       in_text;
    logic [4:0] col;
    logic       line;
    logic [7:0] ch;
    logic [127:0] name_vec, name_sh;
    logic [3:0] digit;
    logic [7:0] glyph_bits;

    assign dx = drawX_d - X0_L;
    assign dy = drawY_d - Y0_L;
    assign in_text = (drawX_d >= X0) && (drawX_d < X0 + W) && (drawY_d >= Y0) && (drawY_d < Y0 + H);
    assign box     = (drawX_d + 10'd4 >= X0) && (drawX_d < X0 + W + 4) &&
                     (drawY_d + 10'd4 >= Y0) && (drawY_d < Y0 + H + 4);

    assign col  = dx[7:3];
    assign line = dy[4];

    always_comb begin
        name_vec = name_of(name_idx);
        nc       = col - 5'd8;                                  // name character index 0..15 for columns 8..23
        name_sh  = name_vec >> {(4'd15 - nc[3:0]), 3'b000};
        digit    = 4'd0;
        ch       = 8'h20;
        if (!line) begin
            case (col)
                5'd0: ch = "F"; 5'd1: ch = "I"; 5'd2: ch = "L"; 5'd3: ch = "T";
                5'd4: ch = "E"; 5'd5: ch = "R"; 5'd6: ch = ":"; 5'd7: ch = " ";
                default: ch = name_sh[7:0];
            endcase
        end else begin
            case (col)
                5'd0: ch = "F"; 5'd1: ch = "R"; 5'd2: ch = "A"; 5'd3: ch = "M";
                5'd4: ch = "E"; 5'd5: ch = ":"; 5'd6: ch = " "; 5'd7: ch = " ";
                5'd8, 5'd9, 5'd10, 5'd11, 5'd12, 5'd13: begin
                    digit = bcd[4*(5 - (col - 5'd8)) +: 4];     // most significant digit first
                    ch    = 8'h30 + {4'b0, digit};
                end
                default: ch = 8'h20;
            endcase
        end
    end

    hud_font_rom font (.glyph(ch[5:0] - 6'h20), .row(dy[3:0]), .bits(glyph_bits));

    assign text = in_text && glyph_bits[3'd7 - dx[2:0]];
endmodule
