// Lesson 7: each request occupies one clock cycle, followed by an idle gap.
class fifo_driver;
    virtual fifo_if vif;
    mailbox #(fifo_transaction) gen2drv;
    int unsigned transactions_driven;

    function new(virtual fifo_if vif,
                 mailbox #(fifo_transaction) gen2drv);
        this.vif = vif;
        this.gen2drv = gen2drv;
        this.transactions_driven = 0;
    endfunction

    // The caller states how many requests to receive; the default is two.
    // The top must initialize inputs and release reset before calling run().
    task run(input int unsigned num_transactions = 2,
             input bit back_to_back = 0);
        fifo_transaction tr;

        repeat (num_transactions) begin
            gen2drv.get(tr);
            if (tr == null)
                $fatal(1, "Driver received a null transaction");

            @(negedge vif.clk);
            vif.wr_en = tr.wr_en;
            vif.rd_en = tr.rd_en;
            vif.wdata = tr.wdata;
            if (tr.rst_n === 1'b0 || tr.rst_n === 1'b1)
                vif.rst_n = tr.rst_n;

            if (!back_to_back) begin
                @(negedge vif.clk);
                vif.wr_en = 1'b0;
                vif.rd_en = 1'b0;
            end
            transactions_driven = transactions_driven + 1;
        end
        if (back_to_back) begin
            @(negedge vif.clk);
            vif.wr_en = 1'b0;
            vif.rd_en = 1'b0;
        end
    endtask
endclass
