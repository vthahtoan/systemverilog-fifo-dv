
class fifo_monitor;
    virtual fifo_if vif;
    mailbox #(fifo_transaction) mon2scb;

    function new(virtual fifo_if vif,
                 mailbox #(fifo_transaction) mon2scb);
        this.vif = vif;
        this.mon2scb = mon2scb;
    endfunction

    task run(input int unsigned num_samples = 8);
        fifo_transaction tr;

        repeat (num_samples) begin
            
            tr = new();

            @(posedge vif.clk);
            
            
            tr.rst_n = vif.rst_n;
            tr.wr_en = vif.wr_en;
            tr.rd_en = vif.rd_en;
            tr.wdata = vif.wdata;
            tr.full_before = vif.full;
            tr.empty_before = vif.empty;

            
            
            #1ns;
            tr.rdata = vif.rdata;
            tr.full = vif.full;
            tr.empty = vif.empty;

            mon2scb.put(tr);
        end
    endtask
endclass
