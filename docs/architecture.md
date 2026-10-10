# Architecture and timing

The simulation top instantiates the clock, interface and DUT, creates a test, drives startup reset and provides a watchdog. Test/environment code selects stimulus and coordinates finite completion counts.

| Component | Responsibility |
|---|---|
| fifo_transaction | Request fields plus monitor observation fields |
| fifo_generator | Fresh request objects, directed plans and per-object seeded randomization |
| fifo_driver | Mailbox requests to interface signals on negative clock edges |
| fifo_monitor | Capture inputs/pre-edge flags at posedge, then registered outputs after NBA updates |
| fifo_scoreboard | Independent reference queue, last expected rdata and automatic comparisons |
| fifo_coverage | Checked request/occupancy samples and separate reset samples |
| fifo_environment | Shared handles/mailboxes, concurrent tasks and completion/traffic/coverage checks |
| fifo_assertions | Bound temporal checks of RTL state and pointer behavior |

`gen2drv` and `mon2scb` are typed mailboxes. Producers send fresh objects so subsequent updates cannot overwrite an observation already queued for a consumer. Driver/monitor hold virtual interface handles referring to the single interface instance.

## Sampling

The clock period is 10 ns. Driver and reset stimulus change at negedge. Monitor samples requests and flags at posedge before DUT nonblocking updates, waits 1 ns, then samples `rdata`, `full` and `empty`. This is a fixed-clock timing contract, not a general clocking-block solution.

Scoreboard snapshots queue size before mutating it. Both accepted-operation decisions use that snapshot; accepted reads pop the oldest entry and accepted writes push the input data. Pre-edge and post-edge flags are checked against expected occupancy. An unaccepted read retains the last expected output.

On synchronous reset the scoreboard counts discarded entries, clears the queue and expects zero `rdata`/empty/not-full. Final accounting requires:

```text
accepted_writes = accepted_reads + discarded_entries
pending_entries = 0
```

Coverage is sampled only after the checks for that cycle pass. Operational/reset coverage groups are separate; reset contents are classified using occupancy before the reset edge.

SVA observes sampled state at posedge. A next-edge consequent sees the NBA results from the prior edge. Reset properties therefore check synchronous reset without an asynchronous `disable iff` that would hide reset behavior.

## Completion and failure

Environment checks expected driven/sample/reset counts, nonempty useful traffic, final queue accounting and empty mailboxes. Boundary cases require every request/occupancy cross cell; reset requires all reset occupancy bins. Tops have watchdog timeouts. Source compilation failures cannot fall back to a previous work library.

Positive test success requires the correct PASS marker and no simulator Error/Fatal. Negative tests require successful compilation followed by the intended runtime checker failure, with no normal PASS marker. License/load/compile failures do not constitute successful defect detection.

## Checker elaboration

Each class-based top contains a module-scoped bind into sync_fifo. The checker prints SVA ACTIVE at startup; the run script rejects a missing instance. The final compiler logs contain no compilation-unit bind warning, and native coverage reports include assertion/cover-property statistics.
