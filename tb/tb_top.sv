`timescale 1ns/1ps

// Lesson 8: one write/read with monitoring of reset and idle cycles too.
module tb_top;
    import fifo_tb_pkg::*;

    // Module-scoped bind is elaborated with this testbench top.
    bind sync_fifo fifo_assertions fifo_checks (
        .clk(clk), .rst_n(rst_n), .wr_en(wr_en), .rd_en(rd_en),
        .full(full), .empty(empty), .rdata(rdata),
        .count(count), .wr_ptr(wr_ptr), .rd_ptr(rd_ptr)
    );

    logic clk = 1'b0;
    always #5 clk = ~clk;

    fifo_if fifo_bus(clk);
    fifo_test test;

    sync_fifo dut (
        .clk(clk),
        .rst_n(fifo_bus.rst_n),
        .wr_en(fifo_bus.wr_en),
        .rd_en(fifo_bus.rd_en),
        .wdata(fifo_bus.wdata),
        .rdata(fifo_bus.rdata),
        .full(fifo_bus.full),
        .empty(fifo_bus.empty)
    );

    initial begin
        fifo_bus.rst_n = 1'b0;
        fifo_bus.wr_en = 1'b0;
        fifo_bus.rd_en = 1'b0;
        fifo_bus.wdata = 8'h00;
        test = new(fifo_bus);

        fork
            test.run();
            begin : reset_control
                repeat (2) @(negedge clk);
                fifo_bus.rst_n = 1'b1;
            end
        join

        $display("PASS: tb_top lesson08 (%0d sampled cycles)",
                 test.env.scb.samples_checked);
        $finish;
    end

    initial begin
        #1000;
        $fatal(1, "Timeout: lesson08 did not finish");
    end
endmodule
