// First functional coverage model: requests x pre-edge expected occupancy.
// This is a fixed 8-bit, depth-16 model, matching the current specification.
class fifo_coverage;
    int unsigned sample_count;
    int unsigned reset_sample_count;
    int unsigned reset_hits[3];
    // Report mirror: rows = empty/middle/full; columns = {wr_en, rd_en}.
    // These counters expose missing bins in the transcript without a GUI.
    int unsigned hits[3][4];

    covergroup cg with function sample(bit wr_en, bit rd_en, int pre_count);
        option.per_instance = 1;
        option.at_least = 1;

        cp_req: coverpoint {wr_en, rd_en} {
            bins idle  = {2'b00};
            bins write = {2'b10};
            bins read  = {2'b01};
            bins both  = {2'b11};
        }

        cp_occ: coverpoint pre_count {
            bins empty  = {0};
            bins middle = {[1:15]};
            bins full   = {16};
        }

        // All 12 combinations are intentional, including rejected requests.
        req_x_occ: cross cp_req, cp_occ;
    endgroup

    covergroup reset_cg with function sample(int pre_count);
        option.per_instance = 1;
        cp_reset_occ: coverpoint pre_count {
            bins empty   = {0};
            bins partial = {[1:15]};
            bins full    = {16};
        }
    endgroup

    function new();
        cg = new();
        reset_cg = new();
        sample_count = 0;
        reset_sample_count = 0;
        foreach (reset_hits[state_idx]) reset_hits[state_idx] = 0;
        foreach (hits[state_idx, req_idx])
            hits[state_idx][req_idx] = 0;
    endfunction

    // Reset is synchronous: pre_count is the content discarded at this edge.
    function void sample_reset(int pre_count);
        int state_idx;
        if ($isunknown(pre_count) || pre_count < 0 || pre_count > 16)
            $fatal(1, "Invalid reset coverage occupancy");
        state_idx = (pre_count == 0) ? 0 : ((pre_count == 16) ? 2 : 1);
        reset_cg.sample(pre_count);
        reset_hits[state_idx]++;
        reset_sample_count++;
    endfunction

    // Called only after the scoreboard has checked this non-reset cycle.
    function void sample(fifo_transaction tr, int pre_count);
        int state_idx;
        int req_idx;

        if (tr == null)
            $fatal(1, "Coverage received a null observation");
        if (tr.rst_n !== 1'b1 ||
            $isunknown({tr.wr_en, tr.rd_en, pre_count}) ||
            pre_count < 0 || pre_count > 16)
            $fatal(1, "Invalid coverage sample: reset/requests/occupancy");

        if (pre_count == 0)
            state_idx = 0;
        else if (pre_count == 16)
            state_idx = 2;
        else
            state_idx = 1;
        req_idx = {tr.wr_en, tr.rd_en};

        cg.sample(tr.wr_en, tr.rd_en, pre_count);
        hits[state_idx][req_idx] = hits[state_idx][req_idx] + 1;
        sample_count = sample_count + 1;
    endfunction

    function string state_name(int state_idx);
        case (state_idx)
            0: return "empty";
            1: return "middle";
            2: return "full";
            default: return "invalid";
        endcase
    endfunction

    function string request_name(int req_idx);
        case (req_idx)
            0: return "idle";
            1: return "read";
            2: return "write";
            3: return "both";
            default: return "invalid";
        endcase
    endfunction

    function void report();
        int unsigned hit_bins;
        hit_bins = 0;

        $display("COVERAGE MODEL: request x pre-edge occupancy (12 bins; reset excluded)");
        $display("COVERAGE SV: samples=%0d request=%0.2f%% occupancy=%0.2f%% cross=%0.2f%% group=%0.2f%%",
                 sample_count, cg.cp_req.get_inst_coverage(),
                 cg.cp_occ.get_inst_coverage(), cg.req_x_occ.get_inst_coverage(),
                 cg.get_inst_coverage());

        foreach (hits[state_idx, req_idx]) begin
            if (hits[state_idx][req_idx] > 0)
                hit_bins = hit_bins + 1;
            $display("COV BIN: state=%s request=%s hits=%0d %s",
                     state_name(state_idx), request_name(req_idx),
                     hits[state_idx][req_idx],
                     (hits[state_idx][req_idx] > 0) ? "HIT" : "MISS");
        end
        $display("COVERAGE CROSS: hit_bins=%0d total_bins=12 percent=%0.2f%%",
                 hit_bins, 100.0 * hit_bins / 12.0);
        // Functional PASS and completeness of this coverage model are separate.
        if (hit_bins < 12)
            $display("COVERAGE NOTE: missing combinations need targeted tests; see MISS lines.");
        $display("COVERAGE RESET: samples=%0d percent=%0.2f%%",
                 reset_sample_count, reset_cg.get_inst_coverage());
        foreach (reset_hits[state_idx])
            $display("COV RESET BIN: state=%s hits=%0d %s",
                     (state_idx == 1) ? "partial" : state_name(state_idx), reset_hits[state_idx],
                     (reset_hits[state_idx] > 0) ? "HIT" : "MISS");
    endfunction
endclass
