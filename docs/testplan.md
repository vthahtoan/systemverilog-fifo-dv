# Verification plan: implemented 8×16 baseline

The final school regression confirms 27/27 cases PASS, including adjacent seeds 30075 and 10075. Functional covergroups reach 22/22 bins; all ten assertions have non-vacuous passes and zero failures, and all six cover properties are hit in the scenario test instance. See [measured results](verification-results.md). Tests establish the defined simulation goals, rather than formal proof of all behaviors.

| Scenario | Run mode | Requirements | Check |
|---|---|---|---|
| Startup reset, idle, one-byte write/read | smoke, directed | R01, R03–R07, R12 | Data/flags, scoreboard, completion checks |
| Fill and drain, rejected full writes/empty reads | boundary | R03–R08 | Independent queue/data/flags; pointer/count/hold SVA |
| Both requests at empty/interior/full | boundary | R06, R09 | Both accept decisions from pre-edge expected occupancy |
| Repeated fill/drain past pointer wrap | boundary | R04, R10 | FIFO ordering and pointer movement/wrap SVA |
| Requests without driver-inserted idle | back_to_back | R03–R10, R12 | Per-cycle scoreboard and SVA |
| Reset at empty/5 entries/full, requests active during reset | reset | R01, R02, R11 | Reset output/state, discard accounting and recovery data |
| Random requests/data then drain | random | R03–R10, R12 | Continuous independent scoreboard, recorded seed and watchdog |
| Incorrect full threshold | negative-full | Checker quality | Intended runtime mismatch must be detected |
| Corrupted read data | negative-read | Checker quality | Intended runtime mismatch must be detected |

## Functional coverage

| Model | Bins | Sampling source |
|---|---|---|
| Request | idle=00, read=01, write=10, both=11 | Observed requests |
| Operational occupancy | empty=0, middle=1..15, full=16 | Independent pre-edge expected size |
| Request × occupancy | All 12 combinations, including rejected requests | Checked non-reset cycles |
| Reset occupancy | empty, partial=1..15, full | Expected size before synchronous reset |

Reset does not count toward the operational cross. Middle/partial ranges are one bin each. Boundary tests explicitly require 12/12 cross hits; reset requires 3/3 reset bins. Targeted tests create the missing conditions rather than ignoring bins or restricting away invalid-at-boundary requests.

Six cover properties additionally observe full-write rejection, empty-read rejection, both pointer wraps and reset with partial/full contents. Read the native report for hit/attempt counts. The current implementation does not collect RTL statement/branch coverage, data-pattern coverpoints, every interior occupancy as a separate bin, or arbitrary parameter configurations.

## Assertions

Ten properties: known state/signals, count range, flags vs count, synchronous reset, write-only/read-only/unchanged count transitions, output hold, write pointer movement/wrap, read pointer movement/wrap. Assertion failures are fatal in positive runs. Ordered data checking remains the independent scoreboard's responsibility.

## Regression

Full: five fixed positive modes, two deliberate negative cases and 20 random seeds with 500 random requests per seed. Quick: the same fixed cases and three seeds with 200 random requests per seed. The configured directed prefix/readout add traffic beyond the random count. Each run records configuration/version and uses a watchdog.

Native summary, coverage reports, per-case configuration/version/compile/simulation logs and mutant-failure evidence are archived under results/. The current evidence records one final full run; a separate repeated-seed comparison has not been performed. A created UCDB/report alone does not establish a particular percentage.

Future extensions: configurable width/depth, random resets, finer occupancy/data/transition coverage, clocking blocks and UVM. They are outside the completed fixed-baseline implementation.
