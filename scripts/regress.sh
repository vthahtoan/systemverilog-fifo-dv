#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-quick}"
if (( $# > 1 )) || [[ "$MODE" != quick && "$MODE" != full ]]; then
    printf 'Usage: bash scripts/regress.sh quick|full\n' >&2
    exit 2
fi
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$ROOT_DIR/logs"
REG_DIR="$(mktemp -d "$ROOT_DIR/logs/regression_${MODE}_XXXXXX")"
UCDBS=()
PASSED=0
printf 'test\tstatus\tlog_directory\n' > "$REG_DIR/summary.tsv"
printf 'Regression results: %s\n' "$REG_DIR"

run_case() {
    local LABEL="$1"
    shift
    local CASE_LOG="$REG_DIR/${LABEL}.log"
    local CASE_DIR
    printf 'Running: %s\n' "$LABEL"
    if ! bash "$ROOT_DIR/scripts/run.sh" "$@" > "$CASE_LOG" 2>&1; then
        printf '%s\tFAIL\t%s\n' "$LABEL" "$CASE_LOG" >> "$REG_DIR/summary.tsv"
        tail -n 40 "$CASE_LOG"
        printf 'REGRESSION FAIL: %s; results: %s\n' "$LABEL" "$REG_DIR" >&2
        exit 1
    fi
    CASE_DIR="$(sed -n 's/^Saved logs: //p' "$CASE_LOG" | tail -n 1)"
    if [[ ! -d "$CASE_DIR" ]]; then
        printf 'Missing saved-log directory for %s\n' "$LABEL" >&2
        exit 1
    fi
    case "$1" in
        smoke|negative-full|negative-read) ;;
        *) UCDBS+=("$CASE_DIR/coverage.ucdb") ;;
    esac
    printf '%s\tPASS\t%s\n' "$LABEL" "$CASE_DIR" >> "$REG_DIR/summary.tsv"
    PASSED=$((PASSED + 1))
    printf 'PASS: %s\n' "$LABEL"
}

run_case smoke smoke
run_case directed directed
run_case boundary boundary
run_case reset reset
run_case back_to_back back_to_back
run_case negative_full negative-full
run_case negative_read negative-read
if [[ "$MODE" == quick ]]; then
    for SEED in 12345 54321 2026; do
        run_case "random_${SEED}" random 200 "$SEED"
    done
else
    FULL_SEEDS=(
        12345 30075 10075 36102 44021 51940 59859 67778 75697 83616
        91535 99454 107373 115292 123211 131130 139049 146968 154887 162806
    )
    for SEED in "${FULL_SEEDS[@]}"; do
        run_case "random_${SEED}" random 500 "$SEED"
    done
fi

printf 'REGRESSION TESTS PASS: %s cases; results: %s\n' "$PASSED" "$REG_DIR"
if ! command -v vcover >/dev/null 2>&1; then
    printf 'MERGE NOT RUN: vcover not in PATH; individual UCDBs/reports were saved.\n' >&2
    printf 'Use summary.tsv to find the logs; load vcover before merging.\n' >&2
    exit 0
fi
vcover merge -out "$REG_DIR/merged.ucdb" "${UCDBS[@]}" > "$REG_DIR/merge.log" 2>&1
vcover report -cvg -assert -directive -details -output "$REG_DIR/coverage-merged.txt" \
    "$REG_DIR/merged.ucdb" > "$REG_DIR/merge-report.log" 2>&1
if [[ ! -s "$REG_DIR/merged.ucdb" || ! -s "$REG_DIR/coverage-merged.txt" ]]; then
    printf 'Merged database/report missing; see merge logs.\n' >&2
    exit 1
fi
printf 'REGRESSION COMPLETE: %s cases; merged report: %s\n' "$PASSED" "$REG_DIR/coverage-merged.txt"
