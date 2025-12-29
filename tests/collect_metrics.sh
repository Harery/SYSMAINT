#!/bin/bash
#
# collect_metrics.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   Collects test metrics over time for trend analysis
#
# USAGE:
#   bash tests/collect_metrics.sh --output tests/metrics.json

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Defaults
OUTPUT_FILE="tests/metrics.json"
METRICS_DIR="tests/metrics"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --output|-o)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --dir|-d)
            METRICS_DIR="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "OPTIONS:"
            echo "  --output, -o FILE  Output file (default: tests/metrics.json)"
            echo "  --dir, -d DIR     Metrics directory (default: tests/metrics)"
            echo "  --help, -h        Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}[INFO]${NC} Collecting test metrics..."

# Create metrics directory
mkdir -p "$METRICS_DIR"

# Get current timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Get system info
OS_ID=$(grep '^ID=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "unknown")
OS_VERSION=$(grep '^VERSION_ID=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "unknown")
ARCH=$(uname -m)

# Count test suites
TEST_SUITES_COUNT=$(find "$PROJECT_DIR/tests" -name "test_suite_*.sh" -type f | wc -l)

# Count test files
TEST_FILES_COUNT=$(find "$PROJECT_DIR/tests" -name "*.sh" -type f | wc -l)

# Get latest test results if available
LATEST_RESULTS=""
LATEST_TOTAL=0
LATEST_PASSED=0
LATEST_FAILED=0

if [[ -d "$PROJECT_DIR/tests/results" ]]; then
    LATEST_JSON=$(find "$PROJECT_DIR/tests/results" -name "*.json" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
    
    if [[ -n "$LATEST_JSON" ]] && [[ -f "$LATEST_JSON" ]]; then
        LATEST_RESULTS="$LATEST_JSON"
        LATEST_TOTAL=$(jq -r '.summary.total // 0' "$LATEST_JSON" 2>/dev/null || echo "0")
        LATEST_PASSED=$(jq -r '.summary.passed // 0' "$LATEST_JSON" 2>/dev/null || echo "0")
        LATEST_FAILED=$(jq -r '.summary.failed // 0' "$LATEST_JSON" 2>/dev/null || echo "0")
    fi
fi

# Calculate pass rate
if [[ $LATEST_TOTAL -gt 0 ]]; then
    LATEST_PASS_RATE=$((LATEST_PASSED * 100 / LATEST_TOTAL))
else
    LATEST_PASS_RATE=0
fi

# Count metrics files
METRICS_COUNT=$(find "$METRICS_DIR" -name "metrics-*.json" -type f 2>/dev/null | wc -l)

# Create metrics JSON
cat > "$OUTPUT_FILE" << METRICSJSON
{
  "timestamp": "$TIMESTAMP",
  "system": {
    "os_id": "$OS_ID",
    "os_version": "$OS_VERSION",
    "architecture": "$ARCH"
  },
  "infrastructure": {
    "test_suites": $TEST_SUITES_COUNT,
    "test_files": $TEST_FILES_COUNT,
    "metrics_files": $METRICS_COUNT
  },
  "latest_results": {
    "file": "$(basename "$LATEST_RESULTS" 2>/dev/null || echo "none")",
    "total": $LATEST_TOTAL,
    "passed": $LATEST_PASSED,
    "failed": $LATEST_FAILED,
    "pass_rate": $LATEST_PASS_RATE
  }
}
METRICSJSON

# Save historical metrics
cp "$OUTPUT_FILE" "$METRICS_DIR/metrics-$(date +%Y%m%d-%H%M%S).json"

# Keep only last 30 metrics files
find "$METRICS_DIR" -name "metrics-*.json" -type f | sort -r | tail -n +31 | xargs rm -f 2>/dev/null || true

echo -e "${GREEN}[SUCCESS]${NC} Metrics collected!"
echo ""
echo "Metrics saved to:"
echo "  Current:  $OUTPUT_FILE"
echo "  History: $METRICS_DIR/metrics-*.json"
echo ""
echo "Current metrics:"
echo "  Test Suites:    $TEST_SUITES_COUNT"
echo "  Test Files:     $TEST_FILES_COUNT"
if [[ $LATEST_TOTAL -gt 0 ]]; then
    echo "  Latest Results:"
    echo "    Total:        $LATEST_TOTAL"
    echo "    Passed:       $LATEST_PASSED"
    echo "    Failed:       $LATEST_FAILED"
    echo "    Pass Rate:    ${LATEST_PASS_RATE}%"
fi
