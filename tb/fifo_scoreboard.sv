// Independent reference model for the fixed 8-bit, depth-16 FIFO.
class fifo_scoreboard;
    mailbox #(fifo_transaction) mon2scb;
    fifo_coverage cov;
    logic [7:0] expected_queue[$];
    logic [7:0] expected_rdata;
    int unsigned samples_checked;
    int unsigned reset_samples;
    int unsigned accepted_writes;
    int unsigned accepted_reads;
    int unsigned discarded_entries;

    function new(mailbox #(fifo_transaction) mon2scb);
        this.mon2scb = mon2scb;
        this.cov = new();
        this.expected_rdata = 8'h00;
        this.samples_checked = 0;
        this.reset_samples = 0;
        this.accepted_writes = 0;
        this.accepted_reads = 0;
        this.discarded_entries = 0;
    endfunction

    task run(input int unsigned num_samples = 8);
        fifo_transaction tr;
        int pre_count;
        logic write_ok;
        logic read_ok;

        repeat (num_samples) begin
            mon2scb.get(tr);
            if (tr == null)
                $fatal(1, "Scoreboard received a null observation");

            // Snapshot expected occupancy before changing the model.
            pre_count = expected_queue.size();

            if (tr.rst_n === 1'b0) begin
                discarded_entries = discarded_entries + pre_count;
                expected_queue.delete();
                expected_rdata = 8'h00;
                reset_samples = reset_samples + 1;
                // Pre-reset DUT flags may be X on the first reset edge.
            end else if (tr.rst_n === 1'b1) begin
                if ($isunknown({tr.wr_en, tr.rd_en}))
                    $fatal(1, "Unknown request at sample %0d", samples_checked + 1);

                if (tr.full_before !== (pre_count == 16) ||
                    tr.empty_before !== (pre_count == 0))
                    $fatal(1, "Pre-edge flags wrong at sample %0d: expected occupancy=%0d, full=%b empty=%b",
                           samples_checked + 1, pre_count, tr.full_before, tr.empty_before);

                // Acceptance comes from EXPECTED occupancy, not DUT flags.
                // Compute BOTH decisions before pop/push changes the queue.
                write_ok = tr.wr_en && (pre_count < 16);
                read_ok = tr.rd_en && (pre_count > 0);

                if (read_ok) begin
                    expected_rdata = expected_queue.pop_front();
                    accepted_reads = accepted_reads + 1;
                end
                if (write_ok) begin
                    if ($isunknown(tr.wdata))
                        $fatal(1, "Unknown accepted write data at sample %0d", samples_checked + 1);
                    expected_queue.push_back(tr.wdata);
                    accepted_writes = accepted_writes + 1;
                end
                // With no accepted read, expected_rdata keeps its last value.
            end else begin
                $fatal(1, "Unknown reset at sample %0d", samples_checked + 1);
            end

            if (tr.rdata !== expected_rdata ||
                tr.full !== (expected_queue.size() == 16) ||
                tr.empty !== (expected_queue.size() == 0))
                $fatal(1, "Post-edge mismatch at sample %0d: actual rdata=%h full=%b empty=%b; expected rdata=%h occupancy=%0d",
                       samples_checked + 1, tr.rdata, tr.full, tr.empty,
                       expected_rdata, expected_queue.size());

            // Sample observed requests only after all checks have passed.
            // pre_count still refers to BEFORE the model's pop/push above.
            if (tr.rst_n === 1'b1)
                cov.sample(tr, pre_count);
            else
                cov.sample_reset(pre_count);

            samples_checked = samples_checked + 1;
            $display("SCB OK: sample=%0d rst_n=%b wr_en=%b rd_en=%b expected_count=%0d rdata=%h",
                     samples_checked, tr.rst_n, tr.wr_en, tr.rd_en,
                     expected_queue.size(), tr.rdata);
        end
    endtask
endclass
