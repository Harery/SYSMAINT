#!/usr/bin/env bash
# Quick Performance Benchmark - Reduced Test Set
# Author: Mohamed Elharery <Mohamed@Harery.com>
# Copyright (c) 2025 Mohamed Elharery
#
# Faster version with fewer iterations for quick validation

export BENCHMARK_RUNS=1
cd "$(dirname "$0")"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         QUICK PERFORMANCE BENCHMARK (1 run/test)          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Run subset of critical benchmarks
SCRIPT="../sysmaint"

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
