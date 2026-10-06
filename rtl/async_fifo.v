`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.10.2026 17:07:22
// Design Name: 
// Module Name: ASYNC FIFO DESIGN CODE
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


module sync_2ff #(parameter W = 1) (
    input  clk, rst_n,
    input  [W-1:0] d,
    output reg [W-1:0] q
);
    reg [W-1:0] meta;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin meta <= 0; q <= 0; end
        else        begin meta <= d; q <= meta; end
    end
endmodule

module async_fifo #(parameter DW = 8, AW = 4) (
    // write domain
    input               wclk, wrst_n, winc,
    input  [DW-1:0]     wdata,
    output reg          wfull,
    // read domain
    input               rclk, rrst_n, rinc,
    output [DW-1:0]     rdata,
    output reg          rempty
);
    reg [DW-1:0] mem [0:(1<<AW)-1];

    reg  [AW:0] wbin, wptr;   // write binary and gray pointers
    reg  [AW:0] rbin, rptr;   // read binary and gray pointers
    wire [AW:0] wq2_rptr, rq2_wptr;

    // ---------- Write domain ----------
    wire [AW:0] wbin_next  = wbin + (winc & ~wfull);
    wire [AW:0] wgray_next = (wbin_next >> 1) ^ wbin_next;
    wire        wfull_val  = (wgray_next ==
                             {~wq2_rptr[AW:AW-1], wq2_rptr[AW-2:0]});

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin wbin <= 0; wptr <= 0; wfull <= 1'b0; end
        else begin
            wbin  <= wbin_next;
            wptr  <= wgray_next;
            wfull <= wfull_val;
        end
    end

    always @(posedge wclk)
        if (winc & ~wfull) mem[wbin[AW-1:0]] <= wdata;

    // ---------- Read domain ----------
    wire [AW:0] rbin_next  = rbin + (rinc & ~rempty);
    wire [AW:0] rgray_next = (rbin_next >> 1) ^ rbin_next;
    wire        rempty_val = (rgray_next == rq2_wptr);

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin rbin <= 0; rptr <= 0; rempty <= 1'b1; end
        else begin
            rbin   <= rbin_next;
            rptr   <= rgray_next;
            rempty <= rempty_val;
        end
    end

    assign rdata = mem[rbin[AW-1:0]];

    // ---------- Pointer synchronizers ----------
    sync_2ff #(AW+1) sync_w2r (.clk(rclk), .rst_n(rrst_n), .d(wptr), .q(rq2_wptr));
    sync_2ff #(AW+1) sync_r2w (.clk(wclk), .rst_n(wrst_n), .d(rptr), .q(wq2_rptr));
endmodule
