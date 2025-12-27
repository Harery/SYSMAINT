#!/usr/bin/env bash
# CI Test Profile - Tests compatible with GitHub Actions
# Excludes tests requiring external tools (hyperfine, lynis, rkhunter, etc.)
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery

set -euo pipefail

# CI Environment Detection - Set non-interactive mode
export CI=true
export NONINTERACTIVE=true
export AUTO_MODE=true
export ASSUME_YES=true

# Debug Mode - Enable verbose output when DEBUG_TESTS=true
if [[ "${DEBUG_TESTS:-false}" == "true" ]]; then
  set -x  # Enable bash debug mode (prints every command)
  export DEBUG_SYSMAINT=true  # Pass to sysmaint
  echo "=== DEBUG MODE ENABLED ===" >&2
  echo "CI=$CI" >&2
  echo "NONINTERACTIVE=$NONINTERACTIVE" >&2
  echo "AUTO_MODE=$AUTO_MODE" >&2
  echo "DEBUG_SYSMAINT=$DEBUG_SYSMAINT" >&2
  echo "========================" >&2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     CI-COMPATIBLE TEST SUITE (GitHub Actions)            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Running tests that work in CI without external tools..."
echo ""

PASSED=0
FAILED=0

# Function to get timeout for a test suite based on test count
get_suite_timeout() {
    local script="$1"
    # Map of suite timeouts in seconds (based on test count)
    case "$script" in
        test_suite_smoke.sh) echo 300 ;;           # 65 tests ~ 2-3 min
        test_suite_edge.sh) echo 300 ;;            # 67 tests ~ 2-3 min
        test_suite_security.sh) echo 300 ;;        # 36 tests ~ 1-2 min
        test_suite_compliance.sh) echo 300 ;;      # 32 tests ~ 1-2 min
        test_suite_governance.sh) echo 120 ;;      # 15 tests ~ 30s
        test_suite_data_types.sh) echo 180 ;;      # 27 tests ~ 1 min
        test_suite_os_families.sh) echo 180 ;;     # 30 tests ~ 1 min
        test_suite_exit_codes.sh) echo 120 ;;      # 22 tests ~ 30s
        test_suite_environment.sh) echo 120 ;;     # 30 tests ~ 30s
        test_suite_argument_matrix.sh) echo 600 ;; # 94 tests ~ 4-5 min
        test_suite_parallel_execution.sh) echo 300 ;; # 22 tests ~ 1-2 min
        test_suite_error_handling.sh) echo 300 ;;  # varies
        test_suite_gui_mode_extended.sh) echo 120 ;; # GUI tests
        test_json_validation.sh) echo 60 ;;        # JSON tests ~ fast
        *) echo 300 ;;  # default 5 minutes
    esac
}

# Function to run a test suite with timeout protection
run_suite() {
    local name="$1"
    local script="$2"
    local timeout_seconds
    timeout_seconds=$(get_suite_timeout "$script")

    echo -e "${BLUE}=== $name ===${NC}"
    # Add timeout protection to prevent hangs
    if timeout "$timeout_seconds" bash "tests/$script" 2>&1 | tee /tmp/"$script".log; then
        echo -e "${GREEN}✓ $name passed${NC}"
        PASSED=$((PASSED + 1))
    else
        local exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            echo -e "${RED}✗ $name timed out after ${timeout_seconds} seconds${NC}"
        else
            echo -e "${RED}✗ $name failed (exit: $exit_code)${NC}"
        fi
        FAILED=$((FAILED + 1))
    fi
    echo ""
}

# === Core Tests (Always Run) ===
run_suite "Smoke Tests" "test_suite_smoke.sh"
run_suite "Edge Cases" "test_suite_edge.sh"
run_suite "Security Tests" "test_suite_security.sh"
run_suite "Compliance Tests" "test_suite_compliance.sh"
run_suite "Governance Tests" "test_suite_governance.sh"
run_suite "Data Types" "test_suite_data_types.sh"
run_suite "OS Families" "test_suite_os_families.sh"
run_suite "Exit Codes" "test_suite_exit_codes.sh"
run_suite "Environment" "test_suite_environment.sh"
run_suite "Argument Matrix" "test_suite_argument_matrix.sh"
run_suite "Parallel Execution" "test_suite_parallel_execution.sh"
run_suite "Error Handling" "test_suite_error_handling.sh"
run_suite "GUI Mode Extended" "test_suite_gui_mode_extended.sh"
run_suite "JSON Validation" "test_json_validation.sh"

# === Tests Skipped in CI ===
echo -e "${YELLOW}=== Tests Skipped in CI (Require External Tools) ===${NC}"
echo -e "${YELLOW}⚠️  Performance Tests (requires: hyperfine)${NC}"
echo -e "${YELLOW}⚠️  Scanner Tests (requires: lynis, rkhunter)${NC}"
echo -e "${YELLOW}⚠️  Combo Tests (requires: various tools)${NC}"
echo -e "${YELLOW}⚠️  Scanner Performance Tests (requires: benchmark tools)${NC}"
echo ""

# === Summary ===
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              CI TEST RESULTS                                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo -e "Test Suites Passed: ${GREEN}$PASSED${NC}"
echo -e "Test Suites Failed: ${RED}$FAILED${NC}"

# Debug mode additional output
if [[ "${DEBUG_TESTS:-false}" == "true" ]]; then
  echo ""
  echo -e "${YELLOW}=== DEBUG INFO ===${NC}"
  echo -e "Log files location: /tmp/*.log"
  echo -e "Total log lines: $(wc -l /tmp/*.log 2>/dev/null | tail -1 || echo "N/A")"
  echo -e "${YELLOW}==================${NC}"
fi
echo ""

TOTAL=$((PASSED + FAILED))
if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}✅ ALL CI-COMPATIBLE TESTS PASSED (${TOTAL}/${TOTAL})${NC}"
    exit 0
else
    echo -e "${RED}❌ SOME TESTS FAILED (${PASSED}/${TOTAL})${NC}"
    exit 1
fi
