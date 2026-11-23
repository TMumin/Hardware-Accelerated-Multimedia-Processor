`timescale 1ns / 1ps
// OV7670 RGB565 capture -> AXI4-Stream (video) for AXI VDMA S2MM.
// Runs entirely in the camera PCLK domain. Camera outputs 2 bytes per pixel on d[7:0]
// while href is high: byte 1 = {R[4:0], G[5:3]}, byte 2 = {G[2:0], B[4:0]} (COM15 = RGB565).
module ov7670_capture #(
    parameter int WIDTH = 640           // pixels per line (sets tlast)
)(
    input  logic        pclk,
    input  logic        rst,            // active high, quasi-static
    input  logic        cam_vsync,
    input  logic        cam_href,
    input  logic [7:0]  cam_d,

    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TDATA" *)  output logic [15:0] m_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TVALID" *) output logic        m_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TUSER" *)  output logic        m_axis_tuser,   // start of frame
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TLAST" *)  output logic        m_axis_tlast    // end of line
);
    // Register the inputs once (let Vivado pack these into IOB flops)
    logic       vs_q, href_q, href_qq;
    logic [7:0] d_q;
    always_ff @(posedge pclk) begin
        vs_q    <= cam_vsync;
        href_q  <= cam_href;
        href_qq <= href_q;
        d_q     <= cam_d;
    end

    logic        byte_phase;     // 0 = next byte is the high byte
    logic [7:0]  hi_byte;
    logic [9:0]  x;
    logic        sof_pending;

    always_ff @(posedge pclk) begin
        m_axis_tvalid <= 1'b0;
        m_axis_tuser  <= 1'b0;
        m_axis_tlast  <= 1'b0;

        if (rst || vs_q) begin              // VSYNC high = between frames
            byte_phase  <= 1'b0;
            x           <= '0;
            sof_pending <= 1'b1;
        end else if (!href_q) begin         // between lines
            byte_phase <= 1'b0;
            x          <= '0;
        end else begin                      // valid line data
            if (!byte_phase) begin
                hi_byte    <= d_q;
                byte_phase <= 1'b1;
            end else begin
                byte_phase    <= 1'b0;
                m_axis_tdata  <= {hi_byte, d_q};
                m_axis_tvalid <= 1'b1;
                m_axis_tuser  <= sof_pending;
                m_axis_tlast  <= (x == WIDTH - 1);
                sof_pending   <= 1'b0;
                x             <= x + 1'b1;
            end
        end
    end
endmodule