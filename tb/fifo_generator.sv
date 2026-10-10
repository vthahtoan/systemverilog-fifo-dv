
class fifo_generator;
    mailbox #(fifo_transaction) gen2drv;
    fifo_transaction directed_plan[$];

    function new(mailbox #(fifo_transaction) gen2drv);
        this.gen2drv = gen2drv;
    endfunction

    
    function void append_request(bit wr, bit rd, logic [7:0] data,
                                 logic reset_value = 1'bx);
        fifo_transaction tr;
        tr = new();
        tr.wr_en = wr;
        tr.rd_en = rd;
        tr.wdata = data;
        
        tr.rst_n = reset_value;
        directed_plan.push_back(tr);
    endfunction

    function int unsigned build_scenario(string scenario);
        logic [7:0] data;
        directed_plan.delete();
        case (scenario)
            "boundary", "back_to_back": begin
                
                append_request(0, 1, 8'h00); 
                append_request(1, 1, 8'hAB); 
                append_request(1, 0, 8'hCD);
                append_request(0, 0, 8'h00); 
                append_request(0, 1, 8'h00);
                append_request(1, 1, 8'hEF); 
                append_request(0, 1, 8'h00); 
                
                for (int round = 0; round < 3; round++) begin
                    for (int i = 0; i < 16; i++) begin
                        case (round)
                            0: data = i;
                            1: data = 8'hFF - i;
                            2: data = (i % 2 == 0) ? 8'hAA : 8'h55;
                        endcase
                        append_request(1, 0, data);
                    end
                    append_request(0, 0, 8'h00); 
                    append_request(1, 0, 8'hDE); 
                    append_request(1, 1, 8'hAD); 
                    append_request(1, 0, 8'hBE); 
                    append_request(0, 1, 8'h00); 
                    repeat (15) append_request(0, 1, 8'h00);
                    append_request(0, 1, 8'h00); 
                end
            end
            "reset": begin
                append_request(1, 1, 8'hFA, 1'b0); 
                append_request(0, 0, 8'h00, 1'b1);
                for (int i = 0; i < 5; i++)
                    append_request(1, 0, 8'h80 + i);
                append_request(1, 1, 8'hF1, 1'b0); 
                append_request(0, 0, 8'h00, 1'b1);
                append_request(1, 0, 8'hA5);
                append_request(0, 1, 8'h00); 
                for (int i = 0; i < 16; i++)
                    append_request(1, 0, i * 7);
                append_request(1, 1, 8'hF2, 1'b0); 
                append_request(0, 0, 8'h00, 1'b1);
                append_request(0, 1, 8'h00); 
                append_request(1, 0, 8'h5A);
                append_request(0, 1, 8'h00); 
            end
            default: $fatal(1, "Unknown generator scenario: %s", scenario);
        endcase
        return directed_plan.size();
    endfunction

    task run_scenario();
        fifo_transaction tr;
        while (directed_plan.size() > 0) begin
            tr = directed_plan.pop_front();
            gen2drv.put(tr);
        end
    endtask

    
    task run(input int unsigned num_random = 0,
             input int unsigned seed = 12345);
        fifo_transaction tr;
        int unsigned item_seed;

        
        tr = new();
        tr.wr_en = 1'b1;
        tr.rd_en = 1'b0;
        tr.wdata = 8'h11;
        gen2drv.put(tr);

        
        tr = new();
        tr.wr_en = 1'b0;
        tr.rd_en = 1'b1;
        tr.wdata = 8'h00;
        gen2drv.put(tr);

        for (int unsigned i = 0; i < num_random; i++) begin
            tr = new();
            
            
            item_seed = seed + i;
            tr.srandom(item_seed);
            if (!tr.randomize())
                $fatal(1, "Randomization failed: item=%0d seed=%0d", i, item_seed);

            $display("GEN RANDOM: item=%0d seed=%0d wr_en=%b rd_en=%b wdata=%h",
                     i, item_seed, tr.wr_en, tr.rd_en, tr.wdata);
            gen2drv.put(tr);
        end

        if (num_random > 0) begin
            
            
            repeat (16) begin
                tr = new();
                tr.wr_en = 1'b0;
                tr.rd_en = 1'b1;
                tr.wdata = 8'h00;
                gen2drv.put(tr);
            end
        end
    endtask
endclass
