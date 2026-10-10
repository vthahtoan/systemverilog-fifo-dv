// Lesson 8: observe every sampled cycle, including reset and idle cycles.
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
            // Never reuse an object that has already been sent.
            tr = new();

            @(posedge vif.clk);
            // Driver and reset controls change only on negedge in this lesson.
            // These are the inputs and flags before nonblocking RTL updates.
            tr.rst_n = vif.rst_n;
            tr.wr_en = vif.wr_en;
            tr.rd_en = vif.rd_en;
            tr.wdata = vif.wdata;
            tr.full_before = vif.full;
            tr.empty_before = vif.empty;

            // Temporary sampling rule for this fixed 10 ns clock.
            // A clocking-block sampling policy will replace it later.
            #1ns;
            tr.rdata = vif.rdata;
            tr.full = vif.full;
            tr.empty = vif.empty;

            mon2scb.put(tr);
        end
    endtask
endclass
