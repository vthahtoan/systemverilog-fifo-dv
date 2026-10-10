`timescale 1ns/1ps




module fifo_assertions (
    input logic clk, rst_n, wr_en, rd_en, full, empty,
    input logic [7:0] rdata,
    input logic [4:0] count,
    input logic [3:0] wr_ptr, rd_ptr
);
    initial $display("SVA ACTIVE: %m (10 assertions, 6 cover properties)");

    logic past_valid = 0;
    always @(posedge clk) past_valid <= 1;

    a_known: assert property (@(posedge clk)
        past_valid |-> !$isunknown({rst_n, wr_en, rd_en, full, empty,
                                    rdata, count, wr_ptr, rd_ptr}))
        else $fatal(1, "ASSERT FAIL: known state/signals");

    a_range: assert property (@(posedge clk)
        past_valid |-> (count <= 16))
        else $fatal(1, "ASSERT FAIL: count range");

    a_flags: assert property (@(posedge clk)
        past_valid |-> ((full == (count == 16)) && (empty == (count == 0))))
        else $fatal(1, "ASSERT FAIL: flags vs count");

    a_reset: assert property (@(posedge clk)
        (!rst_n) |=> (count == 0 && wr_ptr == 0 && rd_ptr == 0 &&
                      rdata == 0 && !full && empty))
        else $fatal(1, "ASSERT FAIL: synchronous reset");

    a_count_write: assert property (@(posedge clk)
        (past_valid && rst_n && wr_en && !full && !(rd_en && !empty))
        |=> (count == $past(count) + 5'd1))
        else $fatal(1, "ASSERT FAIL: count write");

    a_count_read: assert property (@(posedge clk)
        (past_valid && rst_n && rd_en && !empty && !(wr_en && !full))
        |=> (count == $past(count) - 5'd1))
        else $fatal(1, "ASSERT FAIL: count read");

    a_count_hold: assert property (@(posedge clk)
        (past_valid && rst_n && ((wr_en && !full) == (rd_en && !empty)))
        |=> (count == $past(count)))
        else $fatal(1, "ASSERT FAIL: count hold");

    a_rdata_hold: assert property (@(posedge clk)
        (past_valid && rst_n && !(rd_en && !empty)) |=> (rdata == $past(rdata)))
        else $fatal(1, "ASSERT FAIL: rdata hold");

    a_wr_ptr: assert property (@(posedge clk)
        (past_valid && rst_n) |=>
        (wr_ptr == ($past(wr_ptr) + ($past(wr_en && !full) ? 4'd1 : 4'd0))))
        else $fatal(1, "ASSERT FAIL: write pointer movement/wrap");

    a_rd_ptr: assert property (@(posedge clk)
        (past_valid && rst_n) |=>
        (rd_ptr == ($past(rd_ptr) + ($past(rd_en && !empty) ? 4'd1 : 4'd0))))
        else $fatal(1, "ASSERT FAIL: read pointer movement/wrap");

    c_full_write_rejected: cover property (@(posedge clk)
        past_valid && rst_n && full && wr_en && !rd_en);
    c_empty_read_rejected: cover property (@(posedge clk)
        past_valid && rst_n && empty && rd_en && !wr_en);
    c_write_wrap: cover property (@(posedge clk)
        past_valid && rst_n && wr_en && !full && wr_ptr == 15);
    c_read_wrap: cover property (@(posedge clk)
        past_valid && rst_n && rd_en && !empty && rd_ptr == 15);
    c_reset_partial: cover property (@(posedge clk)
        past_valid && !rst_n && count > 0 && count < 16);
    c_reset_full: cover property (@(posedge clk)
        past_valid && !rst_n && count == 16);
endmodule
