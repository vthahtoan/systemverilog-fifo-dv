// Shared signals for the fixed 8-bit, depth-16 FIFO.
interface fifo_if (input logic clk);
    logic       rst_n;
    logic       wr_en;
    logic       rd_en;
    logic [7:0] wdata;
    logic [7:0] rdata;
    logic       full;
    logic       empty;

    // Clocking blocks / modports will be added in the timing lesson.
endinterface
