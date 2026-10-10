# Measured verification results

School run: regression_full_yEiH7Q, 2026-10-10, QuestaSim 2021.2_1 linux_x86_64.

| Metric | Recorded result | Evidence |
|---|---|---|
| Regression | 27/27 PASS: 5 fixed positive, 2 deliberate negative, 20 random | [summary.tsv](../results/regression_full_yEiH7Q/summary.tsv) |
| Random traffic | 500 randomized requests per seed; 20 seeds | Per-case config/simulation logs |
| Operational request × occupancy cross | 12/12 bins, 100% | [Merged report](../results/regression_full_yEiH7Q/coverage-merged.txt) |
| Reset occupancy | 3/3 bins, 100% | Same merged report |
| Full functional covergroup model | 22/22 bins, 100%: 4 request + 3 occupancy + 12 cross + 3 reset | Same merged report |
| SVA | 10 properties, zero failures, non-vacuous passes for every property | Native assertion tables under three top-instance paths |
| Scenario cover properties | 6/6 hit across boundary/reset/back-to-back tests | /fifo_scenario_tb/dut/fifo_checks in merged report |
| Compilation | 27 cases, zero errors/warnings; no vlog-2650 | Per-case compile.log |

The same ten assertion definitions appear under three top-instance paths (30 result rows); this is not 30 different assertions. Assertion tables retain pass, vacuous, attempts and active counts; some next-edge attempts remain active at finite simulation end. Zero failures does not constitute formal proof.

## Directed traffic

| Test | Driven requests | Checked samples | Accepted writes | Accepted reads | Discarded by reset |
|---|---|---|---|---|---|
| boundary | 118 | 240 | 54 | 54 | 0 |
| back_to_back | 118 | 122 | 54 | 54 | 0 |
| reset | 32 | 68 | 23 | 2 | 21 |

All three finish with zero pending entries. Boundary/back-to-back each hit all 12 operational cross cells; reset hits all three reset occupancy bins.

## Cover-property hits in the scenario instance

| Property | Hits |
|---|---|
| Full-write rejection | 6 |
| Empty-read rejection | 9 |
| Write-pointer wrap | 7 |
| Read-pointer wrap | 6 |
| Reset with partial contents | 1 |
| Reset with full contents | 1 |

## Interpreting percentages

The native report's overall filtered instance metric is **85.18%**. This is different from the functional covergroup metric: cover directives are reported separately under each top. The minimal tb_top directed test has 0/6 directive hits, the random top has 4/6, and the scenario top has 6/6. The claim here is 100% of the specified functional covergroup model, plus all six scenario cover properties hit; it is not 100% of all report metrics or RTL code coverage.

The model groups occupancy 1–15 into one middle/partial bin. It does not measure every interior occupancy independently, every data value, all transitions, arbitrary parameters or RTL statement/branch coverage. These are outside this project's recorded goals.

## Reproduction and provenance

Current seeds include adjacent 30075 and 10075; configs and output both confirm their execution. Source/scripts in this repository match the final downloaded backup byte for byte. source-checksums.sha256 records those distributed files; school run-time source hashes were not separately captured. A standalone replay comparison is not part of the evidence.

An earlier run exposed an unelaborated compilation-unit bind. The final revision moves bind into each class-based testbench top, prints a checker-instance marker and rejects a missing checker. This final run has no bind warning and includes native assertion statistics. Only final-run reports are included here.
