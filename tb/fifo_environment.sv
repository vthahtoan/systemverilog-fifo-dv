// Directed or random verification with finite, matching completion counts.
class fifo_environment;
    virtual fifo_if vif;
    mailbox #(fifo_transaction) gen2drv;
    mailbox #(fifo_transaction) mon2scb;
    fifo_generator gen;
    fifo_driver drv;
    fifo_monitor mon;
    fifo_scoreboard scb;

    function new(virtual fifo_if vif);
        this.vif = vif;
        gen2drv = new();
        mon2scb = new();
        gen = new(gen2drv);
        drv = new(vif, gen2drv);
        mon = new(vif, mon2scb);
        scb = new(mon2scb);
    endfunction

    task run(input int unsigned num_random = 0,
             input int unsigned seed = 12345,
             input string scenario = "baseline");
        int unsigned num_requests;
        int unsigned num_samples;
        int unsigned expected_resets;
        bit back_to_back;

        back_to_back = (scenario == "back_to_back");
        expected_resets = (scenario == "reset") ? 8 : 2;
        if (scenario == "baseline") begin
            num_requests = 2 + num_random;
            if (num_random > 0) num_requests = num_requests + 16;
        end else begin
            num_requests = gen.build_scenario(scenario);
        end

        // Fixed lesson timing: 2 reset cycles, reset released at 20 ns,
        // two cycles per request, and observation through the idle tail.
        num_samples = (back_to_back ? num_requests : 2 * num_requests) + 4;
        $display("TEST SCENARIO: name=%s back_to_back=%b", scenario, back_to_back);
        $display("TEST CONFIG: random=%0d seed=%0d requests=%0d samples=%0d",
                 num_random, seed, num_requests, num_samples);

        fork
            begin
                if (scenario == "baseline") gen.run(num_random, seed);
                else gen.run_scenario();
            end
            begin
                // Monitor starts immediately, so reset is observed too.
                wait (vif.rst_n === 1'b1);
                drv.run(num_requests, back_to_back);
            end
            mon.run(num_samples);
            scb.run(num_samples);
        join

        // Counts make an idle-only test fail instead of reporting success.
        if (scb.samples_checked != num_samples || scb.reset_samples != expected_resets ||
            drv.transactions_driven != num_requests ||
            scb.accepted_writes < 1 || scb.accepted_reads < 1)
            $fatal(1, "Incomplete test: samples=%0d resets=%0d writes=%0d reads=%0d driven=%0d",
                   scb.samples_checked, scb.reset_samples,
                   scb.accepted_writes, scb.accepted_reads,
                   drv.transactions_driven);

        if (scb.expected_queue.size() != 0 ||
            scb.accepted_writes != scb.accepted_reads + scb.discarded_entries)
            $fatal(1, "Readout incomplete: pending=%0d writes=%0d reads=%0d",
                   scb.expected_queue.size(), scb.accepted_writes, scb.accepted_reads);

        if (scenario == "baseline" && num_random == 0 &&
            (scb.accepted_writes != 1 || scb.accepted_reads != 1))
            $fatal(1, "Directed baseline must accept exactly one write/read");
        if (gen2drv.num() != 0 || mon2scb.num() != 0)
            $fatal(1, "Unconsumed transactions remain at end of test");
        if (scb.cov.sample_count != scb.samples_checked - scb.reset_samples)
            $fatal(1, "Coverage missed non-reset observations");
        if (scb.cov.reset_sample_count != scb.reset_samples)
            $fatal(1, "Coverage missed reset observations");

        if (scenario == "boundary" || scenario == "back_to_back") begin
            if (scb.accepted_writes != 54 || scb.accepted_reads != 54)
                $fatal(1, "Boundary scenario did not exercise all traffic");
            foreach (scb.cov.hits[state_idx, req_idx])
                if (scb.cov.hits[state_idx][req_idx] == 0)
                    $fatal(1, "Boundary scenario missed request/occupancy bin");
        end
        if (scenario == "reset") begin
            if (scb.accepted_writes != 23 || scb.accepted_reads != 2 ||
                scb.discarded_entries != 21)
                $fatal(1, "Reset scenario traffic/discard counts wrong");
            foreach (scb.cov.reset_hits[state_idx])
                if (scb.cov.reset_hits[state_idx] == 0)
                    $fatal(1, "Reset scenario missed occupancy bin");
        end

        $display("RESET SUMMARY: reset_samples=%0d discarded_entries=%0d",
                 scb.reset_samples, scb.discarded_entries);
        $display("TEST SUMMARY: driven=%0d samples=%0d accepted_writes=%0d accepted_reads=%0d pending=%0d",
                 drv.transactions_driven, scb.samples_checked,
                 scb.accepted_writes, scb.accepted_reads, scb.expected_queue.size());
        scb.cov.report();
    endtask
endclass
