`timescale 1ns/1ps

// SCENARIO=0: boundary; 1: synchronous reset; 2: continuous requests.
module fifo_scenario_tb #(parameter int unsigned SCENARIO = 0);
    import fifo_tb_pkg::*;

    // Module-scoped bind is elaborated with this testbench top.
    bind sync_fifo fifo_assertions fifo_checks (
        .clk(clk), .rst_n(rst_n), .wr_en(wr_en), .rd_en(rd_en),
        .full(full), .empty(empty), .rdata(rdata),
        .count(count), .wr_ptr(wr_ptr), .rd_ptr(rd_ptr)
    );
    localparam string SCENARIO_NAME =
        (SCENARIO == 0) ? "boundary" : ((SCENARIO == 1) ? "reset" : "back_to_back");
    logic clk = 1'b0;
    always #5 clk = ~clk;
    fifo_if fifo_bus(clk);
    fifo_test test;

    sync_fifo dut (
        .clk(clk), .rst_n(fifo_bus.rst_n),
        .wr_en(fifo_bus.wr_en), .rd_en(fifo_bus.rd_en),
        .wdata(fifo_bus.wdata), .rdata(fifo_bus.rdata),
        .full(fifo_bus.full), .empty(fifo_bus.empty)
    );

    initial begin
        if (SCENARIO > 2) $fatal(1, "Unsupported SCENARIO=%0d", SCENARIO);
        fifo_bus.rst_n = 0;
        fifo_bus.wr_en = 0;
        fifo_bus.rd_en = 0;
        fifo_bus.wdata = 0;
        test = new(fifo_bus);
        fork
            test.run_scenario(SCENARIO_NAME);
            begin
                repeat (2) @(negedge clk);
                fifo_bus.rst_n = 1;
            end
        join
        $display("PASS: fifo_scenario_tb scenario=%s requests=%0d samples=%0d",
                 SCENARIO_NAME, test.env.drv.transactions_driven,
                 test.env.scb.samples_checked);
        $finish;
    end

    initial begin
        #20000ns;
        $fatal(1, "Timeout: scenario=%s", SCENARIO_NAME);
    end
endmodule
