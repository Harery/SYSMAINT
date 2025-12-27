#!/usr/bin/env bash
# Performance Regression Detection Script
# Checks if current performance exceeds baseline thresholds
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery

set -euo pipefail

# Force C locale for consistent number formatting
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Baseline values from PERFORMANCE_BASELINE.md (Ubuntu native)
BASELINE_AVG=2.998
BASELINE_MEDIAN=2.966
BASELINE_P90=3.660
BASELINE_P95=3.946
BASELINE_P99=4.080

# Performance thresholds (percentage of baseline)
WARNING_THRESHOLD=20  # 20% degradation
CRITICAL_THRESHOLD=50 # 50% degradation
MAX_ACCEPTABLE=10.0   # Maximum acceptable time in seconds

# Test configuration
ITERATIONS=5
WARMUP_RUNS=1

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Performance Regression Detection Test                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Baseline (Ubuntu 24.04): ${BASELINE_AVG}s average"
echo "Warning Threshold: >${WARNING_THRESHOLD}% degradation"
echo "Critical Threshold: >${CRITICAL_THRESHOLD}% degradation"
echo "Max Acceptable: ${MAX_ACCEPTABLE}s"
echo ""
echo "Running ${ITERATIONS} iterations (${WARMUP_RUNS} warmup runs)..."
echo ""

# Set CI environment for consistent testing
export CI=true
export NONINTERACTIVE=true
export AUTO_MODE=true
export ASSUME_YES=true

# Warmup runs (not counted)
for ((i=1; i<=WARMUP_RUNS; i++)); do
    echo -n "Warmup run ${i}/${WARMUP_RUNS}... "
    bash sysmaint --dry-run >/dev/null 2>&1 || true
    echo "done"
done
echo ""

# Run performance tests
declare -a times
for ((i=1; i<=ITERATIONS; i++)); do
    echo -n "Iteration ${i}/${ITERATIONS}... "
    output=$(bash -c "time bash sysmaint --dry-run" 2>&1 >/dev/null || true)

    # Extract real time from bash built-in time output
    # Format: "real\t0m3.237s"
    real_time=$(echo "$output" | grep "^real" | awk '{print $2}')

    # Parse time in format "0mX.XXXs" or " XmX.XXXs"
    if [[ $real_time =~ ([0-9]+)m([0-9]+\.[0-9]+)s ]]; then
        minutes=${BASH_REMATCH[1]}
        seconds=${BASH_REMATCH[2]}
        total_seconds=$(echo "$minutes * 60 + $seconds" | bc)
    elif [[ $real_time =~ ([0-9]+\.[0-9]+)s ]]; then
        total_seconds=${BASH_REMATCH[1]}
    else
        echo -e "${RED}FAILED to parse time${NC}"
        continue
    fi

    times+=("$total_seconds")
    printf "%.3fs\n" "$total_seconds"
done
echo ""

# Calculate statistics
if [ ${#times[@]} -eq 0 ]; then
    echo -e "${RED}ERROR: No valid measurements collected${NC}"
    exit 1
fi

# Sort times for percentile calculation
IFS=$'\n' sorted_times=($(sort -n <<<"${times[*]}"))
unset IFS

# Calculate average
sum=0
for time in "${times[@]}"; do
    sum=$(echo "$sum + $time" | bc)
done
average=$(echo "scale=3; $sum / ${#times[@]}" | bc)

# Get median
median_idx=$((${#times[@]} / 2))
median=${sorted_times[$median_idx]}

# Get p90 (90th percentile)
p90_idx=$((${#sorted_times[@]} * 90 / 100 - 1))
p90=${sorted_times[$p90_idx]}

# Get p95 (95th percentile)
p95_idx=$((${#sorted_times[@]} * 95 / 100 - 1))
p95=${sorted_times[$p95_idx]}

# Get p99 (99th percentile)
p99_idx=$((${#sorted_times[@]} * 99 / 100 - 1))
p99=${sorted_times[$p99_idx]}

echo -e "${BLUE}=== Results ===${NC}"
echo "Average:     $(printf "%.3f" "$average")s (baseline: ${BASELINE_AVG}s)"
echo "Median:      $(printf "%.3f" "$median")s (baseline: ${BASELINE_MEDIAN}s)"
echo "90th percentile: $(printf "%.3f" "$p90")s (baseline: ${BASELINE_P90}s)"
echo "95th percentile: $(printf "%.3f" "$p95")s (baseline: ${BASELINE_P95}s)"
echo "99th percentile: $(printf "%.3f" "$p99")s (baseline: ${BASELINE_P99}s)"
echo ""

# Calculate degradation from baseline
avg_degradation=$(LC_ALL=C echo "scale=1; ($average - $BASELINE_AVG) / $BASELINE_AVG * 100" | bc)
p95_degradation=$(LC_ALL=C echo "scale=1; ($p95 - $BASELINE_P95) / $BASELINE_P95 * 100" | bc)

echo -e "${BLUE}=== Degradation from Baseline ===${NC}"
echo "Average:     ${avg_degradation}%"
echo "95th percentile: ${p95_degradation}%"
echo ""

# Determine status
exit_code=0
status="${GREEN}✅ PASS${NC}"

# Check average (using awk for numeric comparison)
if awk "BEGIN {exit !($average > $MAX_ACCEPTABLE)}"; then
    echo -e "${RED}❌ FAILURE: Average time $(printf "%.3f" "$average")s exceeds maximum ${MAX_ACCEPTABLE}s${NC}"
    exit_code=1
    status="${RED}❌ FAIL${NC}"
elif awk "BEGIN {exit !($avg_degradation > $CRITICAL_THRESHOLD)}"; then
    echo -e "${RED}🚨 CRITICAL: Average degraded by ${avg_degradation}% (threshold: ${CRITICAL_THRESHOLD}%)${NC}"
    exit_code=1
    status="${RED}❌ FAIL${NC}"
elif awk "BEGIN {exit !($avg_degradation > $WARNING_THRESHOLD)}"; then
    echo -e "${YELLOW}⚠️  WARNING: Average degraded by ${avg_degradation}% (threshold: ${WARNING_THRESHOLD}%)${NC}"
    status="${YELLOW}⚠️  WARN${NC}"
else
    echo -e "${GREEN}✅ Performance within acceptable range${NC}"
fi

echo ""
echo -e "${BLUE}=== Summary ===${NC}"
echo -e "Status: $status"
echo -e "Exit Code: $exit_code"

exit $exit_code
