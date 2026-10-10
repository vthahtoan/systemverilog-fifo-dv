`timescale 1ns/1ps

// Lesson 9: two directed requests, NUM_RANDOM random requests, 16 reads.
// The default configuration is 38 requests and 80 sampled clock cycles.
module fifo_random_tb #(
    parameter int unsigned NUM_RANDOM = 20,
    parameter int unsigned RANDOM_SEED = 12345
);
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

    localparam int unsigned NUM_REQUESTS =
        2 + NUM_RANDOM + ((NUM_RANDOM > 0) ? 16 : 0);
    localparam int unsigned NUM_SAMPLES = 2 * NUM_REQUESTS + 4;

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
            test.run(NUM_RANDOM, RANDOM_SEED);
            begin : reset_control
                repeat (2) @(negedge clk);
                fifo_bus.rst_n = 1'b1;
            end
        join

        $display("PASS: fifo_random_tb (random=%0d seed=%0d samples=%0d)",
                 NUM_RANDOM, RANDOM_SEED, test.env.scb.samples_checked);
        $finish;
    end

    initial begin
        // Scale the watchdog with the chosen test length (10 ns clock).
        #((NUM_SAMPLES + 10) * 10ns);
        $fatal(1, "Timeout: random test did not finish (seed=%0d)", RANDOM_SEED);
    end
endmodule
