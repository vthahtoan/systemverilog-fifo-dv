// Compile interface first, then this package, then the simulation top.
// The included class files must not also be compiled individually.
package fifo_tb_pkg;
    timeunit 1ns;
    timeprecision 1ps;

    `include "fifo_transaction.sv"
    `include "fifo_generator.sv"
    `include "fifo_driver.sv"
    `include "fifo_monitor.sv"
    `include "fifo_coverage.sv"
    `include "fifo_scoreboard.sv"
    `include "fifo_environment.sv"
    `include "fifo_test.sv"
endpackage
