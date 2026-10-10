// The test owns the environment and selects directed or random stimulus.
class fifo_test;
    fifo_environment env;

    function new(virtual fifo_if vif);
        env = new(vif);
    endfunction

    task run(input int unsigned num_random = 0,
             input int unsigned seed = 12345);
        env.run(num_random, seed);
    endtask

    task run_scenario(input string scenario);
        env.run(0, 12345, scenario);
    endtask
endclass
