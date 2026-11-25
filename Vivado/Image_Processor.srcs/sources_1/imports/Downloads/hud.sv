`timescale 1ns / 1ps
// On-screen display: a small panel in the top-left corner.
//   * Always: the active filter name.
//   * Kernel view (K filter): a divider, the 3x3 kernel, SHIFT and BIAS.
//   * Editing: the selected value is highlighted and a one-line key hint is added.
//
// Purely combinational. drawX_d/drawY_d must be the coordinates aligned with the output pixel.
// `kind` tells the top level what colour this pixel should be:
//   0 = not part of the panel     1 = panel background (dimmed video)   2 = border
//   3 = bright text               4 = dim text / divider                5 = cursor background
//   6 = text on the cursor
module hud #(
    parameter int X0 = 16,
    parameter int Y0 = 16
)(
    input  logic [9:0]         drawX_d,
    input  logic [9:0]         drawY_d,
    input  logic [4:0]         name_idx,
    input  logic               kview,      // show the kernel block
    input  logic               edit,       // editor open: highlight the cursor field and show the key hint
    input  logic [3:0]         cursor,     // 0..8 kernel cell, 9 shift, 10 bias
    input  logic [71:0]        kernel,     // k_i = kernel[8*i +: 8], signed
    input  logic [3:0]         shift,
    input  logic signed [7:0]  bias,
    output logic [2:0]         kind
);
    localparam int COLS  = 22;                    // text columns (8 px each)
    localparam int PADX  = 8;
    localparam int PADY  = 8;
    localparam int PANEL_W = 2*PADX + COLS*8;     // 192

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
            5'd12: name_of = "LAPLACIAN       ";
            default: name_of = "                ";
        endcase
    endfunction

    localparam logic [175:0] HINT = "ARROWS MOVE  +/- EDIT ";   // 22 characters

    // ---------------- panel geometry ----------------
    logic [3:0] nlines;
    logic [10:0] panel_h, ybot;
    logic       in_panel, border;

    assign nlines  = !kview ? 4'd1 : (edit ? 4'd8 : 4'd7);
    assign panel_h = 11'd16 + {3'b0, nlines, 4'b0000};            // 2*PADY + 16*lines
    assign ybot    = Y0 + panel_h;

    assign in_panel = (drawX_d >= X0) && (drawX_d < X0 + PANEL_W) && (drawY_d >= Y0) && ({1'b0, drawY_d} < ybot);
    assign border   = in_panel && ((drawX_d == X0) || (drawX_d == X0 + PANEL_W - 1) ||
                                   (drawY_d == Y0) || ({1'b0, drawY_d} == ybot - 11'd1));

    // ---------------- text grid position ----------------
    localparam int TX0 = X0 + PADX;
    localparam int TY0 = Y0 + PADY;
    logic [9:0] tx, ty;
    logic       in_text;
    logic [4:0] col;
    logic [2:0] ln;
    logic [3:0] row;
    logic [2:0] px;

    assign tx = drawX_d - TX0[9:0];
    assign ty = drawY_d - TY0[9:0];
    assign in_text = (drawX_d >= TX0) && (drawX_d < TX0 + COLS*8) &&
                     (drawY_d >= TY0) && ({1'b0, drawY_d} < TY0 + {3'b0, nlines, 4'b0000});
    assign col = tx[7:3];
    assign ln  = ty[6:4];
    assign row = ty[3:0];
    assign px  = tx[2:0];

    // ---------------- what character goes here ----------------
    logic [127:0] name_vec;
    logic [4:0]   nc;
    logic [3:0]   fld;          // field index 0..10, 15 = none
    logic [1:0]   fpos;         // character within the 4-wide number field
    logic [7:0]   ch;
    logic         bright;       // text colour
    logic         divider;
    logic         is_field;
    logic [31:0]  numtxt;
    logic signed [7:0] val;
    logic [175:0] hint_sh;

    always_comb begin
        name_vec = name_of(name_idx);
        nc       = col;                                  // name occupies columns 0..15
        fld      = 4'd15;
        fpos     = 2'd0;
        ch       = 8'h20;
        bright   = 1'b1;
        divider  = 1'b0;
        is_field = 1'b0;
        hint_sh  = HINT >> {(5'd21 - col), 3'b000};

        case (ln)
            3'd0: ch = (col < 5'd16) ? (name_vec >> {(4'd15 - col[3:0]), 3'b000}) : 8'h20;
            3'd1: divider = kview;
            3'd2, 3'd3, 3'd4: begin
                // kernel rows: cells start at columns 3, 9, 15 (4 characters wide)
                case (col)
                    5'd3,  5'd4,  5'd5,  5'd6:  begin is_field = 1; fld = 4'd3*(ln-3'd2) + 4'd0; fpos = col[1:0] - 2'd3; end
                    5'd9,  5'd10, 5'd11, 5'd12: begin is_field = 1; fld = 4'd3*(ln-3'd2) + 4'd1; fpos = col[1:0] - 2'd1; end
                    5'd15, 5'd16, 5'd17, 5'd18: begin is_field = 1; fld = 4'd3*(ln-3'd2) + 4'd2; fpos = col[1:0] - 2'd3; end
                    default: ;
                endcase
            end
            3'd5: begin   // SHIFT
                bright = 1'b0;
                case (col)
                    5'd3: ch = "S"; 5'd4: ch = "H"; 5'd5: ch = "I"; 5'd6: ch = "F"; 5'd7: ch = "T";
                    5'd9, 5'd10, 5'd11, 5'd12: begin is_field = 1; fld = 4'd9; fpos = col[1:0] - 2'd1; bright = 1'b1; end
                    default: ;
                endcase
            end
            3'd6: begin   // BIAS
                bright = 1'b0;
                case (col)
                    5'd3: ch = "B"; 5'd4: ch = "I"; 5'd5: ch = "A"; 5'd6: ch = "S";
                    5'd9, 5'd10, 5'd11, 5'd12: begin is_field = 1; fld = 4'd10; fpos = col[1:0] - 2'd1; bright = 1'b1; end
                    default: ;
                endcase
            end
            3'd7: begin   // key hint (only present while editing)
                bright = 1'b0;
                ch = hint_sh[7:0];
            end
            default: ;
        endcase

        // value for the selected field
        case (fld)
            4'd0:  val = kernel[7:0];
            4'd1:  val = kernel[15:8];
            4'd2:  val = kernel[23:16];
            4'd3:  val = kernel[31:24];
            4'd4:  val = kernel[39:32];
            4'd5:  val = kernel[47:40];
            4'd6:  val = kernel[55:48];
            4'd7:  val = kernel[63:56];
            4'd8:  val = kernel[71:64];
            4'd9:  val = {4'b0000, shift};
            4'd10: val = bias;
            default: val = 8'sd0;
        endcase

        if (is_field) ch = numtxt >> {(2'd3 - fpos), 3'b000};
    end

    hud_fmt4 fmt (.v(val), .s(numtxt));

    logic [7:0] glyph_bits;
    hud_font_rom font (.glyph(ch[5:0] - 6'h20), .row(row), .bits(glyph_bits));

    // ---------------- final pixel kind ----------------
    logic glyph_on, cell_hl;
    assign glyph_on = in_text && glyph_bits[3'd7 - px];
    assign cell_hl  = in_text && is_field && edit && (fld == cursor);

    always_comb begin
        if (!in_panel)                 kind = 3'd0;
        else if (border)               kind = 3'd2;
        else if (cell_hl)              kind = glyph_on ? 3'd6 : 3'd5;
        else if (in_text && divider)   kind = (row == 4'd7) ? 3'd4 : 3'd1;
        else if (glyph_on)             kind = bright ? 3'd3 : 3'd4;
        else                           kind = 3'd1;
    end
endmodule
