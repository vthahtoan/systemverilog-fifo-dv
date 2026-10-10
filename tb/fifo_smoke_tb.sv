`timescale 1ns/1ps

// First self-checking test. No classes or packages are required.
// Prepared for simulation; no successful run has been recorded yet.
module fifo_smoke_tb;
    logic clk = 1'b0;
    always #5 clk = ~clk;

    logic       rst_n;
    logic       wr_en;
    logic       rd_en;
    logic [7:0] wdata;
    logic [7:0] rdata;
    logic       full;
    logic       empty;
    int checks = 0;

    sync_fifo dut (
        .clk(clk), .rst_n(rst_n),
        .wr_en(wr_en), .rd_en(rd_en), .wdata(wdata),
        .rdata(rdata), .full(full), .empty(empty)
    );

    task automatic check_outputs (
        input logic [7:0] expected_rdata,
        input logic       expected_empty,
        input logic       expected_full,
        input string      label
    );
        // Case inequality detects X/Z as well as wrong known values.
        if (rdata !== expected_rdata ||
            empty !== expected_empty || full !== expected_full)
            $fatal(1, "%s: rdata=%h expected=%h, empty=%b expected=%b, full=%b expected=%b",
                   label, rdata, expected_rdata,
                   empty, expected_empty, full, expected_full);
        checks = checks + 1;
        $display("CHECK OK: %s", label);
    endtask

    initial begin
        rst_n = 1'b0;
        wr_en = 1'b0;
        rd_en = 1'b0;
        wdata = 8'h00;

        // Two rising edges occur while synchronous reset is asserted.
        repeat (2) @(negedge clk);
        check_outputs(8'h00, 1'b1, 1'b0, "reset");
        rst_n = 1'b1;

        // Inputs change at falling edges; DUT updates at rising edges.
        wr_en = 1'b1;
        wdata = 8'h11;
        @(negedge clk);
        check_outputs(8'h00, 1'b0, 1'b0, "write 11");

        wdata = 8'h22;
        @(negedge clk);
        check_outputs(8'h00, 1'b0, 1'b0, "write 22");

        wr_en = 1'b0;
        rd_en = 1'b1;
        @(negedge clk);
        check_outputs(8'h11, 1'b0, 1'b0, "read 11");

        // rd_en stays high: request another read at the next rising edge.
        @(negedge clk);
        check_outputs(8'h22, 1'b1, 1'b0, "read 22");

        @(negedge clk);
        check_outputs(8'h22, 1'b1, 1'b0, "rejected empty read");

        rd_en = 1'b0;
        @(negedge clk);
        check_outputs(8'h22, 1'b1, 1'b0, "idle holds output");

        $display("PASS: fifo_smoke_tb (%0d checks)", checks);
        $finish;
    end

    // An unexpected hang must fail rather than run forever.
    initial begin
        #1000;
        $fatal(1, "TIMEOUT: fifo_smoke_tb did not complete");
    end
endmodule
