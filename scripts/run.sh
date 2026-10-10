#!/usr/bin/env bash
set -euo pipefail

usage() {
    printf 'Usage: bash scripts/run.sh smoke|directed|boundary|reset|back_to_back|negative-full|negative-read|random [NUM_RANDOM [SEED]]\n' >&2
}

if (( $# > 3 )); then usage; exit 2; fi
MODE="${1:-random}"
NUM_RANDOM="${2:-20}"
SEED="${3:-12345}"

case "$MODE" in
    smoke|directed|boundary|reset|back_to_back|negative-full|negative-read)
        if (( $# > 1 )); then usage; exit 2; fi
        ;;
    random)
        if [[ ! "$NUM_RANDOM" =~ ^(0|[1-9][0-9]*)$ ||
              ! "$SEED" =~ ^(0|[1-9][0-9]*)$ ]]; then
            printf 'NUM_RANDOM and SEED must be decimal nonnegative integers.\n' >&2
            exit 2
        fi
        if (( ${#NUM_RANDOM} > 6 || ${#SEED} > 10 )); then
            printf 'NUM_RANDOM must be <=100000; SEED must be <=4294967295.\n' >&2
            exit 2
        fi
        if (( NUM_RANDOM > 100000 || SEED > 4294967295 )); then
            printf 'NUM_RANDOM must be <=100000; SEED must be <=4294967295.\n' >&2
            exit 2
        fi
        ;;
    *) usage; exit 2 ;;
esac

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
for TOOL in vlib vmap vlog vsim; do
    if ! command -v "$TOOL" >/dev/null 2>&1; then
        printf 'Missing tool: %s. Load the school ModelSim/Questa environment first.\n' "$TOOL" >&2
        exit 127
    fi
done

mkdir -p "$ROOT_DIR/build" "$ROOT_DIR/logs"
BUILD_DIR="$(mktemp -d "$ROOT_DIR/build/${MODE}_XXXXXX")"
RUN_ID="$(basename -- "$BUILD_DIR")"
LOG_DIR="$ROOT_DIR/logs/$RUN_ID"
mkdir -p "$LOG_DIR"

trap 'STATUS=$?; if (( STATUS != 0 )); then printf "Run failed (exit %s). Logs: %s\n" "$STATUS" "$LOG_DIR" >&2; fi' EXIT

SOURCES=("$ROOT_DIR/src/fifo.sv")
NEGATIVE_PATTERN=""
case "$MODE" in
    negative-full)
        SOURCES=("$ROOT_DIR/negative/fifo_bad_full.sv")
        NEGATIVE_PATTERN='Post-edge mismatch|ASSERT FAIL: flags vs count'
        ;;
    negative-read)
        SOURCES=("$ROOT_DIR/negative/fifo_bad_read.sv")
        NEGATIVE_PATTERN='Post-edge mismatch'
        ;;
esac
# Keep this array nonempty in every mode: older Bash + nounset rejects
# expansion of an empty array, even when it was initialized with =().
VSIM_ARGS=(-modelsimini "$BUILD_DIR/modelsim.ini" -c -onfinish stop -voptargs=+acc -assertcounts)
case "$MODE" in
    smoke)
        TOP=fifo_smoke_tb
        SOURCES+=("$ROOT_DIR/tb/fifo_smoke_tb.sv")
        EXPECTED_PASS='PASS: fifo_smoke_tb (7 checks)'
        ;;
    directed)
        TOP=tb_top
        SOURCES+=("$ROOT_DIR/tb/fifo_if.sv" "$ROOT_DIR/tb/fifo_tb_pkg.sv" "$ROOT_DIR/tb/tb_top.sv")
        EXPECTED_PASS='PASS: tb_top lesson08 (8 sampled cycles)'
        ;;
    boundary|reset|back_to_back|negative-full|negative-read)
        TOP=fifo_scenario_tb
        SOURCES+=("$ROOT_DIR/tb/fifo_if.sv" "$ROOT_DIR/tb/fifo_tb_pkg.sv" "$ROOT_DIR/tb/fifo_scenario_tb.sv")
        case "$MODE" in
            boundary|negative-full|negative-read) SCENARIO=0 ;;
            reset) SCENARIO=1 ;;
            back_to_back) SCENARIO=2 ;;
        esac
        VSIM_ARGS+=("-gSCENARIO=$SCENARIO")
        EXPECTED_PASS="PASS: fifo_scenario_tb scenario=$MODE "
        if [[ -n "$NEGATIVE_PATTERN" ]]; then
            EXPECTED_PASS="Expected defect detection: $NEGATIVE_PATTERN"
        fi
        ;;
    random)
        TOP=fifo_random_tb
        SOURCES+=("$ROOT_DIR/tb/fifo_if.sv" "$ROOT_DIR/tb/fifo_tb_pkg.sv" "$ROOT_DIR/tb/fifo_random_tb.sv")
        VSIM_ARGS+=("-gNUM_RANDOM=$NUM_RANDOM" "-gRANDOM_SEED=$SEED")
        NUM_REQUESTS=$((2 + NUM_RANDOM))
        if (( NUM_RANDOM > 0 )); then NUM_REQUESTS=$((NUM_REQUESTS + 16)); fi
        NUM_SAMPLES=$((2 * NUM_REQUESTS + 4))
        EXPECTED_PASS="PASS: fifo_random_tb (random=$NUM_RANDOM seed=$SEED samples=$NUM_SAMPLES)"
        ;;
esac

export FIFO_DV_COVERAGE_DIR=""
if [[ "$MODE" != smoke ]]; then
    SOURCES+=("$ROOT_DIR/tb/fifo_assertions.sv")
    if [[ -z "$NEGATIVE_PATTERN" ]]; then FIFO_DV_COVERAGE_DIR="$LOG_DIR"; fi
fi
export FIFO_DV_TEST_NAME="$RUN_ID"

printf 'Mode: %s\nTop: %s\nExpected: %s\nLogs: %s\n' "$MODE" "$TOP" "$EXPECTED_PASS" "$LOG_DIR"
{
    printf 'mode=%s\ntop=%s\n' "$MODE" "$TOP"
    if [[ "$MODE" == random ]]; then
        printf 'num_random=%s\nseed=%s\nrequests=%s\nsamples=%s\n' "$NUM_RANDOM" "$SEED" "$NUM_REQUESTS" "$NUM_SAMPLES"
    fi
    printf 'expected_pass=%s\n' "$EXPECTED_PASS"
    printf 'utc_started=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
} > "$LOG_DIR/config.txt"
vsim -version > "$LOG_DIR/tool-version.log" 2>&1 || true

# Each run uses a fresh library, so failed compilation cannot run stale code.
cd "$BUILD_DIR"
vmap -c 2>&1 | tee "$LOG_DIR/setup.log"
vlib work 2>&1 | tee -a "$LOG_DIR/setup.log"
vmap -modelsimini "$BUILD_DIR/modelsim.ini" work "$BUILD_DIR/work" 2>&1 | tee -a "$LOG_DIR/setup.log"
vlog -modelsimini "$BUILD_DIR/modelsim.ini" -sv -work work \
    "+incdir+$ROOT_DIR/tb" "${SOURCES[@]}" 2>&1 | tee "$LOG_DIR/compile.log"

SIM_STATUS=0
if vsim "${VSIM_ARGS[@]}" -wlf "$LOG_DIR/wave.wlf" \
    "work.$TOP" -do "do {$ROOT_DIR/scripts/batch.do}" \
    2>&1 | tee "$LOG_DIR/simulation.log"; then
    SIM_STATUS=0
else
    SIM_STATUS=$?
fi

# Reject a silently unbound checker, even when the scoreboard passed.
if [[ "$MODE" != smoke ]] && ! grep -Fq 'SVA ACTIVE:' "$LOG_DIR/simulation.log"; then
    printf 'SVA checker was not elaborated; see compile/simulation logs.\n' >&2
    exit 1
fi

if [[ -n "$NEGATIVE_PATTERN" ]]; then
    if grep -Fq 'PASS: fifo_scenario_tb' "$LOG_DIR/simulation.log" ||
       ! grep -Eq '\*\*[[:space:]]+(Error|Fatal):' "$LOG_DIR/simulation.log" ||
       ! grep -Eq "$NEGATIVE_PATTERN" "$LOG_DIR/simulation.log"; then
        printf 'Negative test did not detect the intended RTL defect; see simulation.log.\n' >&2
        exit 1
    fi
    printf 'NEGATIVE TEST PASS: %s (intentional RTL defect detected; simulator exit=%s)\n' "$MODE" "$SIM_STATUS"
    printf 'SUCCESS: %s\nSaved logs: %s\n' "$MODE" "$LOG_DIR"
    exit 0
fi
if (( SIM_STATUS != 0 )); then exit "$SIM_STATUS"; fi

if grep -Eq '\*\*[[:space:]]+(Error|Fatal):' "$LOG_DIR/simulation.log"; then
    printf 'Simulator reported an error/fatal; see simulation.log.\n' >&2
    exit 1
fi
if ! grep -Fq -- "$EXPECTED_PASS" "$LOG_DIR/simulation.log"; then
    printf 'Expected PASS marker was not found; see simulation.log.\n' >&2
    exit 1
fi

if [[ "$MODE" != smoke ]]; then
    if ! grep -Fq 'COVERAGE SV:' "$LOG_DIR/simulation.log" ||
       ! grep -Fq 'COVERAGE CROSS:' "$LOG_DIR/simulation.log"; then
        printf 'Expected coverage report was not found; see simulation.log.\n' >&2
        exit 1
    fi
    grep -E 'COVERAGE |COV (BIN|RESET BIN):' "$LOG_DIR/simulation.log" > "$LOG_DIR/coverage-summary.txt"
    if [[ ! -s "$LOG_DIR/coverage.ucdb" || ! -s "$LOG_DIR/coverage-tool.txt" ]]; then
        printf 'Coverage database/tool report was not saved.\n' >&2
        exit 1
    fi
fi

printf 'SUCCESS: %s\nSaved logs: %s\n' "$MODE" "$LOG_DIR"
