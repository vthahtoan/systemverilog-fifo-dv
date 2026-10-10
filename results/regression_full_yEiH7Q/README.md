# regression_full_yEiH7Q

School run date: 2026-10-10. Tool: QuestaSim 2021.2_1 on Linux. 27/27 cases PASS; 20 seeds include adjacent 30075 and 10075, with 500 random requests each.

| Evidence | Location |
|---|---|
| All 27 statuses and original case-directory identifiers | summary.tsv |
| Native functional, assertion and cover-directive statistics | coverage-merged.txt |
| Merge/report tool output | merge.log, merge-report.log |
| Exact 20-seed list | seeds.txt |
| All 20 random configurations | cases/random_<seed>/config.txt |
| Boundary, reset, back-to-back, two mutations and two favorite seeds | Selected config.txt and simulation.log under cases/ |
| Targeted functional coverage summaries | Boundary/reset/back_to_back coverage-summary.txt |
| Representative successful compilation and simulator version | cases/boundary/compile.log and tool-version.log |
| Intended negative-test detections | runner/negative_full.log, runner/negative_read.log |

All raw case logs were reviewed before curating this compact package. The final run has SVA ACTIVE in all 26 non-smoke cases and no bind compiler warning. Only 24 positive class-based runs enter the UCDB merge; smoke has no class/SVA checker and the two deliberate negative cases are expected to fail their DUT checks.

## Redaction and omitted copies

Only the absolute personal school project path is replaced by <project-root>. Case-folder identifiers, seed values, metrics, errors and statuses are unchanged. summary.tsv uses original school directory identifiers; curated copies are under cases/<test-name>/. Complete raw logs and binary artifacts are kept in the local backup. This compact package intentionally omits repetitive logs rather than replacing them with invented summaries.
