
class fifo_transaction;
    logic       rst_n;
    rand logic       wr_en;
    rand logic       rd_en;
    rand logic [7:0] wdata;

    
    logic       full_before;
    logic       empty_before;

    
    logic [7:0] rdata;
    logic       full;
    logic       empty;
endclass
