# Reading order

Read docs/spec.md first: understand acceptance from pre-edge occupancy, simultaneous read/write, synchronous reset and registered read output.

| Order | File | Explain after reading |
|---|---|---|
| 1 | src/fifo.sv | Memory, pointers, count, accepted requests and nonblocking updates |
| 2 | tb/fifo_if.sv | Shared signal bundle and the virtual interface handle |
| 3 | tb/fifo_transaction.sv | Request versus observation fields |
| 4 | tb/fifo_generator.sv | Fresh objects, directed plans and seeded randomization |
| 5 | tb/fifo_driver.sv | Typed mailbox get, negedge driving and continuous mode |
| 6 | tb/fifo_monitor.sv | Pre-edge inputs and post-NBA outputs |
| 7 | tb/fifo_scoreboard.sv | Independent reference queue, comparisons and reset accounting |
| 8 | tb/fifo_coverage.sv | Coverpoints, cross bins, sampling and missing goals |
| 9 | tb/fifo_assertions.sv | Sampled values, implication, $past, assertions versus cover properties |
| 10 | tb/fifo_environment.sv, tb/fifo_test.sv | Shared handles, parallel tasks, finite completion and goal checks |
| 11 | tb/fifo_scenario_tb.sv, tb/fifo_random_tb.sv | DUT wiring, module-scoped bind, reset, parameters and watchdog |
| 12 | scripts/run.sh, batch.do, regress.sh | Build order, positive/negative outcomes, seeds and UCDB merge |

Then compare docs/testplan.md with docs/verification-results.md. Be able to walk through one empty/both cycle, one full/both cycle, one reset with pending data and an intentional failing RTL mutation. Trace how the monitor observation reaches the scoreboard and how a checked cycle reaches coverage.
