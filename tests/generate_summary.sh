#!/usr/bin/env bash
# Generate Test Summary from all result files
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="$PROJECT_ROOT/test_results"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "# Test Run Summary"
echo "**Date:** $(date -R)"
echo "**Version:** $(grep '^VERSION=' "$PROJECT_ROOT/sysmaint" | cut -d= -f2 | tr -d '"')"
echo ""
echo "## Platform Results"
echo ""

# Collect all summary files
summary_files=("$RESULTS_DIR"/*.summary)
if [[ ${#summary_files[@]} -eq 0 ]]; then
    echo "No test results found. Run tests first."
    exit 1
fi

# Group by platform
declare -A platform_results
declare -A platform_pass
declare -A platform_fail

for summary_file in "${summary_files[@]}"; do
    filename=$(basename "$summary_file" .summary)
    # Extract platform name (remove test suite name)
    platform=$(echo "$filename" | sed 's/_[^_]*_test_suite.*$//' | sed 's/_test_suite.*$//')

    content=$(cat "$summary_file")
    platform_results[$platform]="$content"

    # Count passes and fails
    if [[ "$content" =~ ([0-9]+)\ passed ]]; then
        platform_pass[$platform]=${BASH_REMATCH[1]}
    fi
    if [[ "$content" =~ ([0-9]+)\ failed ]]; then
        platform_fail[$platform]=${BASH_REMATCH[1]}
    fi
done

# Sort platforms alphabetically
sorted_platforms=($(echo "${!platform_results[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

# Display results by platform
for platform in "${sorted_platforms[@]}"; do
    echo "### $platform"
    if [[ -n "${platform_results[$platform]}" ]]; then
        echo "${platform_results[$platform]}"
    fi
    echo ""
done

# Calculate overall statistics
total_pass=0
total_fail=0

for pass_val in "${platform_pass[@]}"; do
    total_pass=$((total_pass + pass_val))
done

for fail_val in "${platform_fail[@]}"; do
    total_fail=$((total_fail + fail_val))
done

total_tests=$((total_pass + total_fail))
pass_rate=0
if [[ $total_tests -gt 0 ]]; then
    pass_rate=$(echo "scale=1; $total_pass * 100 / $total_tests" | bc)
fi

echo "## Overall Statistics"
echo "- Total Tests: $total_tests"
echo "- Passed: $total_pass"
echo "- Failed: $total_fail"
echo "- Pass Rate: ${pass_rate}%"
echo ""

# Generate summary table
echo "## Summary Table"
echo ""
echo "| Platform | Passed | Failed | Total | Pass Rate |"
echo "|----------|--------|--------|-------|-----------|"

for platform in "${sorted_platforms[@]}"; do
    pass=${platform_pass[$platform]:-0}
    fail=${platform_fail[$platform]:-0}
    total=$((pass + fail))
    rate=0
    if [[ $total -gt 0 ]]; then
        rate=$(echo "scale=0; $pass * 100 / $total" | bc)
    fi
    echo "| $platform | $pass | $fail | $total | ${rate}% |"
done

echo ""
echo "---"
echo "**Generated:** $(date)"
