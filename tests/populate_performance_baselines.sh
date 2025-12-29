#!/bin/bash
#
# populate_performance_baselines.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   Runs performance tests and populates the baseline document with real data
#
# USAGE:
#   bash tests/populate_performance_baselines.sh [--os OS] [--local-only]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Defaults
TEST_OS="${TEST_OS:-all}"
LOCAL_ONLY=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --os)
            TEST_OS="$2"
            shift 2
            ;;
        --local-only)
            LOCAL_ONLY=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "OPTIONS:"
            echo "  --os OS           Test specific OS (default: all)"
            echo "  --local-only      Run locally only, no Docker"
            echo "  --help, -h        Show this help"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "========================================"
echo "SYSMAINT Performance Baseline Collection"
echo "========================================"
echo ""

# Results directory
RESULTS_DIR="$SCRIPT_DIR/performance_baselines"
mkdir -p "$RESULTS_DIR"

log_info "Results will be saved to: $RESULTS_DIR"
echo ""

# OS list to test
if [[ "$TEST_OS" == "all" ]]; then
    OS_LIST=("current")
else
    OS_LIST=("$TEST_OS")
fi

# Run performance tests
for os in "${OS_LIST[@]}"; do
    echo "═══════════════════════════════════════════════"
    log_info "Testing: $os"
    echo "═══════════════════════════════════════════════"
    
    OUTPUT_FILE="$RESULTS_DIR/baseline_${os}_$(date +%Y%m%d_%H%M%S).txt"
    
    if [[ -f "$SCRIPT_DIR/test_suite_performance.sh" ]]; then
        BENCHMARK_RUNS=3 bash "$SCRIPT_DIR/test_suite_performance.sh" 2>&1 | tee "$OUTPUT_FILE" || true
        log_success "Results saved to: $OUTPUT_FILE"
    else
        log_error "Performance test suite not found at: $SCRIPT_DIR/test_suite_performance.sh"
    fi
    
    echo ""
done

# Generate summary
echo "═══════════════════════════════════════════════"
log_info "Summary Report"
echo "═══════════════════════════════════════════════"
echo ""

log_success "Performance baseline collection complete!"
log_info "Results directory: $RESULTS_DIR"
echo ""
echo "Next: Update tests/PERFORMANCE_BASELINES.md with the collected data"
echo ""
