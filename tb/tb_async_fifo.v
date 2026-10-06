`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.10.2026 18:24:07
// Design Name: 
// Module Name: tb_async_fifo
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


`timescale 1ns/1ps
module tb_async_fifo;
    parameter DW = 8, AW = 4, N = 500;

    reg wclk = 0, rclk = 0, wrst_n = 0, rrst_n = 0, winc = 0, rinc = 0;
    reg  [DW-1:0] wdata = 0;
    wire [DW-1:0] rdata;
    wire wfull, rempty;

    reg [DW-1:0] expected [0:N-1];
    integer wr_cnt = 0, rd_cnt = 0, errors = 0;

    async_fifo #(DW, AW) dut (
        .wclk(wclk), .wrst_n(wrst_n), .winc(winc), .wdata(wdata), .wfull(wfull),
        .rclk(rclk), .rrst_n(rrst_n), .rinc(rinc), .rdata(rdata), .rempty(rempty)
    );

    always #5 wclk = ~wclk;   // 100 MHz write
    always #13 rclk = ~rclk;   // ~71 MHz read

    initial begin
        #43 wrst_n = 1;
        #9  rrst_n = 1;
    end

    // Writer: random gaps, never writes when full
    initial begin
        wait (wrst_n);
        while (wr_cnt < N) begin
            @(posedge wclk); #1;
            if (!wfull && ($random & 3) != 0) begin
                wdata = $random;
                expected[wr_cnt] = wdata;
                wr_cnt = wr_cnt + 1;
                winc = 1;
            end else winc = 0;
        end
        @(posedge wclk); #1 winc = 0;
    end

    // Reader: random gaps, never reads when empty
    initial begin
        wait (rrst_n);
        while (rd_cnt < N) begin
            @(posedge rclk); #1;
            rinc = (!rempty && ($random & 1));
        end
        rinc = 0;
    end

    // Checker: compare on every successful read
    always @(posedge rclk) begin
        if (rrst_n && rinc && !rempty) begin
            if (rdata !== expected[rd_cnt]) begin
                errors = errors + 1;
                $display("ERROR @%0t: idx %0d exp %h got %h",
                          $time, rd_cnt, expected[rd_cnt], rdata);
            end
            rd_cnt = rd_cnt + 1;
        end
    end

    initial begin
        wait (rd_cnt == N);
        #50;
        if (errors == 0) $display("PASS: %0d words transferred correctly", N);
        else             $display("FAIL: %0d errors", errors);
        $finish;
    end

    initial begin #200000; $display("TIMEOUT"); $finish; end
endmodule
