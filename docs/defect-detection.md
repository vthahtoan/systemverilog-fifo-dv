# Deliberate RTL defect detection

These are intentionally injected defects for checking verification quality. They are not naturally discovered baseline RTL bugs. Separate mutant files are selected by the negative run modes; the baseline source remains unchanged.

| Mutation | File | Expected trigger from source analysis | Checker |
|---|---|---|---|
| full asserted at count 15 instead of 16 | negative/fifo_bad_full.sv | Occupancy reaches 15 but reference model still expects not-full | Post-edge flag comparison; flags/count SVA also checks the invariant |
| XOR read output with 8'h01 | negative/fifo_bad_read.sv | A valid read returns a changed least-significant bit | Independent ordered-data comparison |

The final regression confirms both intended detections through the scoreboard:

- **negative-full:** sample 46, actual full=1 while expected occupancy=15. [Simulation log](../results/regression_full_yEiH7Q/cases/negative_full/simulation.log).
- **negative-read:** sample 12, actual rdata=aa while expected rdata=ab. [Simulation log](../results/regression_full_yEiH7Q/cases/negative_read/simulation.log).

SVA is instantiated in these negative runs, but the scoreboard is the first fatal checker in the recorded failures. Positive-run UCDBs are merged; negative-run failures are preserved as separate logs and excluded from the merged coverage statistics.

```bash
bash scripts/run.sh negative-full
bash scripts/run.sh negative-read
```

The script first requires successful setup/compilation. It then requires simulator Error/Fatal output matching the expected checker message and absence of the normal testbench PASS marker. The regression returns success for this intended detection and keeps the failing simulation log for analysis. An unrelated license/compile failure does not qualify.

Archive the negative simulation logs alongside successful baseline logs, and explain expected versus actual behavior, triggering request, checker message and the exact mutation during review.
