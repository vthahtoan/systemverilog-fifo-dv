// A generator fills requests; a monitor fills a complete cycle observation.
class fifo_transaction;
    logic       rst_n;
    rand logic       wr_en;
    rand logic       rd_en;
    rand logic [7:0] wdata;

    // Flags before the active edge updates the FIFO state.
    logic       full_before;
    logic       empty_before;

    // Registered data and flags after that edge has updated the state.
    logic [7:0] rdata;
    logic       full;
    logic       empty;
endclass
