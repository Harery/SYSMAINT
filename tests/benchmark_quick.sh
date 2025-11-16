#!/usr/bin/env bash
# Unified Benchmarking Tool
# Author: Mohamed Elharery <Mohamed@Harery.com>
# Copyright (c) 2025 Mohamed Elharery
#
# Combined quick benchmark and comparison tool

set -euo pipefail
cd "$(dirname "$0")"

usage() {
    cat << EOF
Usage: $0 <command> [options]

Commands:
  quick                     Run quick benchmark (1 run/test)
  compare <baseline> <curr> Compare two CSV reports

Quick Options:
  (none required)

Compare Options:
  -t, --threshold PERCENT   Regression threshold (default: 20%)
  -h, --help               Show this help

Examples:
  $0 quick
  $0 compare /tmp/sysmaint-benchmarks/benchmark_20251115_120000.csv \\
             /tmp/sysmaint-benchmarks/benchmark_20251115_130000.csv
EOF
    exit 0
}

# ===== Quick Benchmark =====
quick_benchmark() {
    export BENCHMARK_RUNS=1
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║         QUICK PERFORMANCE BENCHMARK (1 run/test)          ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    local SCRIPT="../sysmaint"
    time_test() {
        local name="$1"
        shift
        echo -n "Testing $name... "
        local start=$(date +%s.%N)
        bash "$SCRIPT" "$@" >/dev/null 2>&1 || true
        local end=$(date +%s.%N)
        local elapsed=$(echo "$end - $start" | bc)
        printf "%.3fs\n" "$elapsed"
    }

    echo "Critical Path Tests:"
    time_test "minimal      " --dry-run
    time_test "with-json    " --dry-run --json-summary
    time_test "with-upgrade " --dry-run --upgrade --json-summary
    time_test "with-security" --dry-run --security-audit --json-summary
    time_test "full-load    " --dry-run --upgrade --security-audit --check-zombies \
        --purge-kernels --orphan-purge --json-summary

    echo ""
    echo "Quick benchmark complete!"
    echo "For comprehensive benchmarks, run: bash tests/test_suite_performance.sh"
}

# ===== Compare Reports =====
compare_reports() {
    local BASELINE="$1"
    local CURRENT="$2"
    local THRESHOLD="${3:-1.20}"

    # Colors
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local BLUE='\033[0;34m'
    local NC='\033[0m'

    if [[ ! -f "$BASELINE" ]]; then
        echo "Error: Baseline file not found: $BASELINE"
        exit 1
    fi

    if [[ ! -f "$CURRENT" ]]; then
        echo "Error: Current file not found: $CURRENT"
        exit 1
    fi

    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║         PERFORMANCE COMPARISON REPORT                      ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Baseline: $(basename "$BASELINE")"
    echo "Current:  $(basename "$CURRENT")"
    echo "Regression threshold: $(echo "($THRESHOLD - 1) * 100" | bc)%"
    echo ""

    declare -A baseline_times
    declare -A current_times

    while IFS=',' read -r test_name avg_time rest; do
        if [[ "$test_name" == "Test Name" ]]; then continue; fi
        baseline_times["$test_name"]="$avg_time"
    done < "$BASELINE"

    while IFS=',' read -r test_name avg_time rest; do
        if [[ "$test_name" == "Test Name" ]]; then continue; fi
        current_times["$test_name"]="$avg_time"
    done < "$CURRENT"

    local REGRESSIONS=0
    local IMPROVEMENTS=0
    local NEUTRAL=0

    echo "════════════════════════════════════════════════════════════"
    echo "COMPARISON RESULTS"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    printf "%-35s %12s %12s %10s %10s\n" "Test Name" "Baseline" "Current" "Change" "Status"
    echo "────────────────────────────────────────────────────────────────────────────────────────"

    TEMP_RESULTS=$(mktemp)
    trap "rm -f $TEMP_RESULTS" EXIT

    set +e
    for test_name in "${!current_times[@]}"; do
        current_time="${current_times[$test_name]}"
        baseline_time="${baseline_times[$test_name]:-}"
        
        if [[ -z "$baseline_time" ]]; then
            printf "%-35s %12s %11.3fs %10s ${BLUE}NEW${NC}\n" \
                "$test_name" "N/A" "$current_time" "N/A" >> "$TEMP_RESULTS"
            continue
        fi
        
        ratio=$(echo "scale=3; $current_time / $baseline_time" | bc)
        change_pct=$(echo "scale=1; ($ratio - 1) * 100" | bc)
        
        if (( $(echo "$ratio > $THRESHOLD" | bc -l) )); then
            status_marker="${RED}SLOWER${NC}"
            ((REGRESSIONS++))
        elif (( $(echo "$ratio < 0.90" | bc -l) )); then
            status_marker="${GREEN}FASTER${NC}"
            ((IMPROVEMENTS++))
        else
            status_marker="${YELLOW}STABLE${NC}"
            ((NEUTRAL++))
        fi
        
        printf "%-35s %11.3fs %11.3fs %9.1f%% %b\n" \
            "$test_name" "$baseline_time" "$current_time" "$change_pct" "$status_marker" >> "$TEMP_RESULTS"
    done
    set -e

    sort "$TEMP_RESULTS"

    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "SUMMARY"
    echo "════════════════════════════════════════════════════════════"
    echo ""

    local TOTAL_COMPARED=$((REGRESSIONS + IMPROVEMENTS + NEUTRAL))
    echo "Total tests compared: $TOTAL_COMPARED"
    echo ""

    if [[ $REGRESSIONS -gt 0 ]]; then
        echo -e "${RED}Regressions (slower):${NC} $REGRESSIONS"
    fi
    if [[ $IMPROVEMENTS -gt 0 ]]; then
        echo -e "${GREEN}Improvements (faster):${NC} $IMPROVEMENTS"
    fi
    if [[ $NEUTRAL -gt 0 ]]; then
        echo -e "${YELLOW}Stable (no significant change):${NC} $NEUTRAL"
    fi

    echo ""

    if [[ $REGRESSIONS -gt 0 ]]; then
        echo -e "${RED}⚠ Performance regressions detected!${NC}"
        exit 1
    elif [[ $IMPROVEMENTS -gt 0 ]]; then
        echo -e "${GREEN}✓ Performance improvements detected!${NC}"
        exit 0
    else
        echo -e "${YELLOW}○ Performance stable${NC}"
        exit 0
    fi
}

# ===== Main Dispatcher =====
if [[ $# -eq 0 ]]; then
    usage
fi

COMMAND="$1"
shift

case "$COMMAND" in
    quick)
        quick_benchmark
        ;;
    compare)
        if [[ $# -lt 2 ]]; then
            echo "Error: compare requires baseline and current CSV files"
            usage
        fi
        THRESHOLD=1.20
        while [[ $# -gt 2 ]]; do
            case "$1" in
                -t|--threshold)
                    THRESHOLD=$(echo "1 + $2 / 100" | bc -l)
                    shift 2
                    ;;
                *)
                    echo "Error: Unknown option $1"
                    usage
                    ;;
            esac
        done
        compare_reports "$1" "$2" "$THRESHOLD"
        ;;
    -h|--help)
        usage
        ;;
    *)
        echo "Error: Unknown command: $COMMAND"
        usage
        ;;
esac
