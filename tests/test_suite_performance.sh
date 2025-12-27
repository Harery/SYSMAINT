#!/usr/bin/env bash
# Performance Benchmark Test Suite
# Author: Mohamed Elharery <Mohamed@Harery.com>
# Copyright (c) 2025 Mohamed Elharery
#
# Automated timing tests for sysmaint performance characteristics

set -euo pipefail
cd "$(dirname "$0")/.."

SCRIPT="./sysmaint"
BENCHMARK_RUNS="${BENCHMARK_RUNS:-3}"
RESULTS_DIR="/tmp/sysmaint-benchmarks"
mkdir -p "$RESULTS_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Results tracking
declare -A TIMINGS
declare -A MEMORY_PEAKS
declare -A DISK_READS
declare -A DISK_WRITES

# Statistics functions
calculate_stats() {
    local values=("$@")
    local sum=0
    local count=${#values[@]}
    for val in "${values[@]}"; do
        sum=$(echo "$sum + $val" | bc)
    done
    local avg=0
    if (( count > 0 )); then
        avg=$(echo "scale=3; $sum / $count" | bc)
    fi
    local min=${values[0]:-0}
    local max=${values[0]:-0}
    for val in "${values[@]}"; do
        if (( $(echo "$val < $min" | bc -l) )); then min=$val; fi
        if (( $(echo "$val > $max" | bc -l) )); then max=$val; fi
    done
    IFS=$'\n' sorted=($(sort -n <<<"${values[*]}"))
    unset IFS
    local mid=$((count / 2))
    local median=${sorted[$mid]:-0}
    # Percentiles (nearest-rank)
    local p90=0 p95=0 p99=0
    if (( count > 0 )); then
        local idx90=$(( (90*count + 99) / 100 - 1 ))
        local idx95=$(( (95*count + 99) / 100 - 1 ))
        local idx99=$(( (99*count + 99) / 100 - 1 ))
        (( idx90 < 0 )) && idx90=0; (( idx90 >= count )) && idx90=$((count-1))
        (( idx95 < 0 )) && idx95=0; (( idx95 >= count )) && idx95=$((count-1))
        (( idx99 < 0 )) && idx99=0; (( idx99 >= count )) && idx99=$((count-1))
        p90=${sorted[$idx90]:-0}
        p95=${sorted[$idx95]:-0}
        p99=${sorted[$idx99]:-0}
    fi
    echo "$avg $min $max $median $p90 $p95 $p99"
}

# Integer statistics (for memory in KB)
calculate_stats_int() {
    local values=("$@")
    local sum=0
    local count=${#values[@]}

    # Calculate sum (integers)
    for val in "${values[@]}"; do
        sum=$((sum + val))
    done
    # Integer average (rounded)
    local avg=$(( (sum + count/2) / count ))

    # Min/Max (integers)
    local min=${values[0]}
    local max=${values[0]}
    for val in "${values[@]}"; do
        (( val < min )) && min=$val
        (( val > max )) && max=$val
    done

    # Median (sort integers)
    IFS=$'\n' sorted=($(printf '%s\n' "${values[@]}" | sort -n))
    unset IFS
    local mid=$((count / 2))
    local median=${sorted[$mid]}

    echo "$avg $min $max $median"
}

# Benchmark runner
run_benchmark() {
    local test_name="$1"
    shift
    local args=("$@")
    
    echo -e "${BLUE}Benchmarking: ${test_name}${NC}"
    echo "  Running $BENCHMARK_RUNS iterations..."
    
    local times=()
    local mem_peaks=()
    
    for ((i=1; i<=BENCHMARK_RUNS; i++)); do
        echo -n "  Run $i/$BENCHMARK_RUNS... "
        
        # Capture timing with time command
        local start_time=$(date +%s.%N)
        
        # Run with /usr/bin/time for detailed metrics
        local time_output=$(mktemp)
        /usr/bin/time -f "wall:%e user:%U sys:%S maxrss:%M" \
            bash "$SCRIPT" "${args[@]}" >/dev/null 2>"$time_output" || true
        
        local end_time=$(date +%s.%N)
        local elapsed=$(echo "$end_time - $start_time" | bc)
        
        # Parse metrics
        local wall_time=$(grep -oP 'wall:\K[0-9.]+' "$time_output" || echo "$elapsed")
        local mem_kb=$(grep -oP 'maxrss:\K[0-9]+' "$time_output" || echo "0")
        
        times+=("$wall_time")
        mem_peaks+=("$mem_kb")
        
        rm -f "$time_output"
        echo "✓ ${wall_time}s"
    done
    
    # Calculate statistics
    read avg min max median p90 p95 p99 < <(calculate_stats "${times[@]}")
    read mem_avg mem_min mem_max mem_median < <(calculate_stats_int "${mem_peaks[@]}")
    
    # Store results
    TIMINGS["$test_name"]="$avg,$min,$max,$median,$p90,$p95,$p99"
    MEMORY_PEAKS["$test_name"]="$mem_avg,$mem_min,$mem_max,$mem_median"
    
    # Display summary
        printf "  ${GREEN}Time:${NC}   avg=%.3fs  min=%.3fs  max=%.3fs  median=%.3fs  p90=%.3fs  p95=%.3fs  p99=%.3fs\n" \
            "$avg" "$min" "$max" "$median" "$p90" "$p95" "$p99"
    printf "  ${GREEN}Memory:${NC} avg=%dKB  min=%dKB  max=%dKB  median=%dKB\n" \
        "$mem_avg" "$mem_min" "$mem_max" "$mem_median"
    echo ""
}

# Performance thresholds (seconds)
# Adjust for CI environments which are typically slower
if [[ "${CI:-false}" == "true" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]]; then
    THRESHOLD_FAST=5.0
    THRESHOLD_ACCEPTABLE=20.0
    THRESHOLD_SLOW=60.0
else
    THRESHOLD_FAST=3.0
    THRESHOLD_ACCEPTABLE=10.0
    THRESHOLD_SLOW=30.0
fi

check_threshold() {
    local test_name="$1"
    local avg_time="$2"
    
    if (( $(echo "$avg_time < $THRESHOLD_FAST" | bc -l) )); then
        echo -e "${GREEN}✓ FAST${NC} (<${THRESHOLD_FAST}s)"
    elif (( $(echo "$avg_time < $THRESHOLD_ACCEPTABLE" | bc -l) )); then
        echo -e "${GREEN}✓ ACCEPTABLE${NC} (<${THRESHOLD_ACCEPTABLE}s)"
    elif (( $(echo "$avg_time < $THRESHOLD_SLOW" | bc -l) )); then
        echo -e "${YELLOW}⚠ SLOW${NC} (<${THRESHOLD_SLOW}s)"
    else
        echo -e "${RED}✗ TOO SLOW${NC} (>${THRESHOLD_SLOW}s)"
    fi
}

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         SYSMAINT PERFORMANCE BENCHMARK SUITE               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Configuration:"
echo "  Benchmark runs per test: $BENCHMARK_RUNS"
echo "  Results directory: $RESULTS_DIR"
echo "  Performance thresholds:"
echo "    Fast:       < ${THRESHOLD_FAST}s"
echo "    Acceptable: < ${THRESHOLD_ACCEPTABLE}s"
echo "    Slow:       < ${THRESHOLD_SLOW}s"
echo ""

# ==================== BASELINE BENCHMARKS ====================
echo "═══════════════════════════════════════════════════════════"
echo "BASELINE BENCHMARKS (Dry-Run Mode)"
echo "═══════════════════════════════════════════════════════════"
echo ""

run_benchmark "baseline-minimal" --dry-run
run_benchmark "baseline-default" --dry-run --json-summary
run_benchmark "baseline-with-upgrade" --dry-run --upgrade --json-summary

# ==================== FEATURE BENCHMARKS ====================
echo "═══════════════════════════════════════════════════════════"
echo "FEATURE-SPECIFIC BENCHMARKS"
echo "═══════════════════════════════════════════════════════════"
echo ""

run_benchmark "feature-security-audit" --dry-run --security-audit --json-summary
run_benchmark "feature-check-zombies" --dry-run --check-zombies --json-summary
run_benchmark "feature-browser-cache" --dry-run --browser-cache-report --json-summary
run_benchmark "feature-kernel-purge" --dry-run --purge-kernels --json-summary
run_benchmark "feature-orphan-purge" --dry-run --orphan-purge --json-summary

# ==================== COMBINED LOAD BENCHMARKS ====================
echo "═══════════════════════════════════════════════════════════"
echo "COMBINED LOAD BENCHMARKS"
echo "═══════════════════════════════════════════════════════════"
echo ""

run_benchmark "load-moderate" --dry-run --upgrade --security-audit --check-zombies --json-summary
run_benchmark "load-heavy" --dry-run --upgrade --security-audit --check-zombies \
    --purge-kernels --orphan-purge --browser-cache-report --json-summary
run_benchmark "load-maximum" --dry-run --upgrade --security-audit --check-zombies \
    --purge-kernels --orphan-purge --browser-cache-purge --fstrim \
    --drop-caches --clear-journal --json-summary

# ==================== SCALABILITY BENCHMARKS ====================
echo "═══════════════════════════════════════════════════════════"
echo "SCALABILITY BENCHMARKS"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Test with different journal retention values
run_benchmark "scale-journal-1d" --dry-run --journal-days=1 --json-summary
run_benchmark "scale-journal-30d" --dry-run --journal-days=30 --json-summary
run_benchmark "scale-journal-365d" --dry-run --journal-days=365 --json-summary

# Test with different kernel counts
run_benchmark "scale-kernel-1" --dry-run --purge-kernels --keep-kernels=1 --json-summary
run_benchmark "scale-kernel-5" --dry-run --purge-kernels --keep-kernels=5 --json-summary
run_benchmark "scale-kernel-10" --dry-run --purge-kernels --keep-kernels=10 --json-summary

# ==================== DISPLAY MODE BENCHMARKS ====================
echo "═══════════════════════════════════════════════════════════"
echo "DISPLAY MODE BENCHMARKS"
echo "═══════════════════════════════════════════════════════════"
echo ""

run_benchmark "display-quiet" --dry-run --progress=quiet --json-summary
run_benchmark "display-dots" --dry-run --progress=dots --json-summary
run_benchmark "display-spinner" --dry-run --progress=spinner --json-summary
run_benchmark "display-countdown" --dry-run --progress=countdown --json-summary

# ==================== JSON OUTPUT BENCHMARKS ====================
echo "═══════════════════════════════════════════════════════════"
echo "JSON OUTPUT BENCHMARKS"
echo "═══════════════════════════════════════════════════════════"
echo ""

run_benchmark "json-disabled" --dry-run
run_benchmark "json-enabled" --dry-run --json-summary
run_benchmark "json-full-telemetry" --dry-run --upgrade --security-audit \
    --check-zombies --browser-cache-report --json-summary

# ==================== GENERATE REPORT ====================
echo "═══════════════════════════════════════════════════════════"
echo "PERFORMANCE SUMMARY REPORT"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Create CSV report
REPORT_FILE="$RESULTS_DIR/benchmark_$(date +%Y%m%d_%H%M%S).csv"
echo "Test Name,Avg Time (s),Min Time (s),Max Time (s),Median Time (s),p90 (s),p95 (s),p99 (s),Avg Memory (KB),Status" > "$REPORT_FILE"

echo "Performance Rankings:"
echo ""
printf "%-35s %10s %10s %10s %15s\n" "Test Name" "Avg Time" "Min Time" "Max Time" "Status"
echo "────────────────────────────────────────────────────────────────────────────────"

# Sort by average time
for test_name in "${!TIMINGS[@]}"; do
    IFS=',' read -r avg min max median p90 p95 p99 <<< "${TIMINGS[$test_name]}"
    IFS=',' read -r mem_avg mem_min mem_max mem_median <<< "${MEMORY_PEAKS[$test_name]}"
    
    printf "%-35s %9.3fs %9.3fs %9.3fs  " "$test_name" "$avg" "$min" "$max"
    check_threshold "$test_name" "$avg"
    
    # Add to CSV
    status="ACCEPTABLE"
    if (( $(echo "$avg < $THRESHOLD_FAST" | bc -l) )); then
        status="FAST"
    elif (( $(echo "$avg >= $THRESHOLD_SLOW" | bc -l) )); then
        status="SLOW"
    fi
    echo "$test_name,$avg,$min,$max,$median,$p90,$p95,$p99,$mem_avg,$status" >> "$REPORT_FILE"
done | sort -t, -k2 -n

echo ""
echo "Detailed report saved to: $REPORT_FILE"

# ==================== REGRESSION DETECTION ====================
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "REGRESSION DETECTION"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check if previous benchmark exists
PREV_REPORT=$(ls -t "$RESULTS_DIR"/benchmark_*.csv 2>/dev/null | sed -n '2p')
if [[ -f "$PREV_REPORT" ]]; then
    echo "Comparing with previous run: $(basename "$PREV_REPORT")"
    echo ""
    
    # Compare key metrics
    REGRESSION_FOUND=false
    REGRESSION_THRESHOLD=1.20  # 20% slower = regression
    
    while IFS=',' read -r test_name new_avg rest; do
        if [[ "$test_name" == "Test Name" ]]; then continue; fi
        
        old_avg=$(grep "^$test_name," "$PREV_REPORT" | cut -d',' -f2)
        if [[ -n "$old_avg" ]]; then
            ratio=$(echo "scale=3; $new_avg / $old_avg" | bc)
            if (( $(echo "$ratio > $REGRESSION_THRESHOLD" | bc -l) )); then
                pct=$(echo "scale=1; ($ratio - 1) * 100" | bc)
                echo -e "${RED}⚠ REGRESSION:${NC} $test_name is ${pct}% slower (was ${old_avg}s, now ${new_avg}s)"
                REGRESSION_FOUND=true
            fi
        fi
    done < "$REPORT_FILE"
    
    if [[ "$REGRESSION_FOUND" == "false" ]]; then
        echo -e "${GREEN}✓ No performance regressions detected${NC}"
    fi
else
    echo "No previous benchmark found. This is the baseline."
fi

# ==================== SYSTEM INFO ====================
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "SYSTEM INFORMATION"
echo "═══════════════════════════════════════════════════════════"
echo ""

echo "Host: $(hostname)"
echo "OS: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Kernel: $(uname -r)"
echo "CPU: $(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)"
echo "CPU Cores: $(nproc)"
echo "Memory: $(free -h | awk '/^Mem:/ {print $2}')"
echo "sysmaint version: $(grep "SCRIPT_VERSION=" "$SCRIPT" | head -1 | cut -d'"' -f2)"
echo "Benchmark date: $(date '+%Y-%m-%d %H:%M:%S')"

# ==================== FINAL SUMMARY ====================
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              BENCHMARK SUITE COMPLETED                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

TOTAL_TESTS=${#TIMINGS[@]}
echo "Total benchmark scenarios: $TOTAL_TESTS"
echo "Total iterations: $((TOTAL_TESTS * BENCHMARK_RUNS))"
echo ""

# Calculate overall statistics
all_times=()
for test_name in "${!TIMINGS[@]}"; do
    IFS=',' read -r avg min max median p90 p95 p99 <<< "${TIMINGS[$test_name]}"
    all_times+=("$avg")
done

if [[ ${#all_times[@]} -gt 0 ]]; then
    read overall_avg overall_min overall_max overall_median overall_p90 overall_p95 overall_p99 < <(calculate_stats "${all_times[@]}")
    printf "Overall average time: %.3fs (median=%.3fs p90=%.3fs p95=%.3fs p99=%.3fs)\n" "$overall_avg" "$overall_median" "$overall_p90" "$overall_p95" "$overall_p99"
    printf "Fastest test avg: %.3fs\n" "$overall_min"
    printf "Slowest test avg: %.3fs\n" "$overall_max"
fi

echo ""
echo "Results directory: $RESULTS_DIR"
echo "Latest report: $REPORT_FILE"
echo ""

# Exit with success if no slow tests detected
SLOW_COUNT=0
for test_name in "${!TIMINGS[@]}"; do
    IFS=',' read -r avg min max median <<< "${TIMINGS[$test_name]}"
    if (( $(echo "$avg >= $THRESHOLD_SLOW" | bc -l) )); then
        ((SLOW_COUNT++))
    fi
done

if [[ $SLOW_COUNT -gt 0 ]]; then
    echo -e "${YELLOW}⚠ Warning: $SLOW_COUNT test(s) exceeded slow threshold${NC}"
    exit 0  # Still exit 0 for CI, but warn
else
    echo -e "${GREEN}✓ All tests within acceptable performance thresholds${NC}"
    exit 0
fi
