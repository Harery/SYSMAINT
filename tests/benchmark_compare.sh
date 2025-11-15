#!/usr/bin/env bash
# Performance Comparison Tool
# Author: Mohamed Elharery <Mohamed@Harery.com>
# Copyright (c) 2025 Mohamed Elharery
#
# Compare two benchmark reports to detect regressions

set -euo pipefail

usage() {
    cat << EOF
Usage: $0 <baseline_report.csv> <current_report.csv>

Compare two benchmark reports and detect performance regressions.

Options:
  -t, --threshold PERCENT   Regression threshold (default: 20%)
  -h, --help               Show this help message

Example:
  $0 /tmp/sysmaint-benchmarks/benchmark_20251115_120000.csv \\
     /tmp/sysmaint-benchmarks/benchmark_20251115_130000.csv
EOF
    exit 0
}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

THRESHOLD=1.20  # 20% slower = regression

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--threshold)
            THRESHOLD=$(echo "1 + $2 / 100" | bc -l)
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            if [[ -z "${BASELINE:-}" ]]; then
                BASELINE="$1"
            elif [[ -z "${CURRENT:-}" ]]; then
                CURRENT="$1"
            else
                echo "Error: Too many arguments"
                usage
            fi
            shift
            ;;
    esac
done

if [[ -z "${BASELINE:-}" || -z "${CURRENT:-}" ]]; then
    echo "Error: Both baseline and current report files required"
    usage
fi

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

# Parse and compare
declare -A baseline_times
declare -A current_times

# Load baseline
while IFS=',' read -r test_name avg_time rest; do
    if [[ "$test_name" == "Test Name" ]]; then continue; fi
    baseline_times["$test_name"]="$avg_time"
done < "$BASELINE"

# Load current
while IFS=',' read -r test_name avg_time rest; do
    if [[ "$test_name" == "Test Name" ]]; then continue; fi
    current_times["$test_name"]="$avg_time"
done < "$CURRENT"

# Compare
REGRESSIONS=0
IMPROVEMENTS=0
NEUTRAL=0

echo "════════════════════════════════════════════════════════════"
echo "COMPARISON RESULTS"
echo "════════════════════════════════════════════════════════════"
echo ""
printf "%-35s %12s %12s %10s %10s\n" "Test Name" "Baseline" "Current" "Change" "Status"
echo "────────────────────────────────────────────────────────────────────────────────────────"

for test_name in "${!current_times[@]}"; do
    current_time="${current_times[$test_name]}"
    baseline_time="${baseline_times[$test_name]:-}"
    
    if [[ -z "$baseline_time" ]]; then
        printf "%-35s %12s %11.3fs %10s ${BLUE}NEW${NC}\n" \
            "$test_name" "N/A" "$current_time" "N/A"
        continue
    fi
    
    ratio=$(echo "scale=3; $current_time / $baseline_time" | bc)
    change_pct=$(echo "scale=1; ($ratio - 1) * 100" | bc)
    
    printf "%-35s %11.3fs %11.3fs %9.1f%% " \
        "$test_name" "$baseline_time" "$current_time" "$change_pct"
    
    if (( $(echo "$ratio > $THRESHOLD" | bc -l) )); then
        echo -e "${RED}SLOWER${NC}"
        ((REGRESSIONS++))
    elif (( $(echo "$ratio < 0.90" | bc -l) )); then
        echo -e "${GREEN}FASTER${NC}"
        ((IMPROVEMENTS++))
    else
        echo -e "${YELLOW}STABLE${NC}"
        ((NEUTRAL++))
    fi
done | sort

# Check for removed tests
echo ""
echo "Removed tests:"
for test_name in "${!baseline_times[@]}"; do
    if [[ -z "${current_times[$test_name]:-}" ]]; then
        echo "  - $test_name"
    fi
done

# Summary
echo ""
echo "════════════════════════════════════════════════════════════"
echo "SUMMARY"
echo "════════════════════════════════════════════════════════════"
echo ""

TOTAL_COMPARED=$((REGRESSIONS + IMPROVEMENTS + NEUTRAL))
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

# Calculate overall statistics
all_baseline=()
all_current=()
for test_name in "${!current_times[@]}"; do
    baseline_time="${baseline_times[$test_name]:-}"
    if [[ -n "$baseline_time" ]]; then
        all_baseline+=("$baseline_time")
        all_current+=("${current_times[$test_name]}")
    fi
done

if [[ ${#all_baseline[@]} -gt 0 ]]; then
    # Calculate averages
    sum_baseline=0
    sum_current=0
    for i in "${!all_baseline[@]}"; do
        sum_baseline=$(echo "$sum_baseline + ${all_baseline[$i]}" | bc)
        sum_current=$(echo "$sum_current + ${all_current[$i]}" | bc)
    done
    
    avg_baseline=$(echo "scale=3; $sum_baseline / ${#all_baseline[@]}" | bc)
    avg_current=$(echo "scale=3; $sum_current / ${#all_current[@]}" | bc)
    overall_change=$(echo "scale=1; ($avg_current / $avg_baseline - 1) * 100" | bc)
    
    echo "Overall Performance:"
    printf "  Baseline average: %.3fs\n" "$avg_baseline"
    printf "  Current average:  %.3fs\n" "$avg_current"
    printf "  Overall change:   %+.1f%%\n" "$overall_change"
fi

echo ""

# Exit code based on regressions
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
