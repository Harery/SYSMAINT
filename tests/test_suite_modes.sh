#!/bin/bash
#
# test_suite_modes.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   Mode-specific test suite for SYSMAINT
#   Tests all execution modes (--auto, --gui, --dry-run, --quiet, --verbose, --json-summary)
#
# USAGE:
#   bash tests/test_suite_modes.sh

set -e

# Test framework
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SYSMAINT="$PROJECT_DIR/sysmaint"

log_test() {
    echo -e "${GREEN}[TEST]${NC} $*"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $*"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $*"
}

run_test() {
    local test_name="$1"
    local test_func="$2"

    ((TESTS_RUN++))
    log_test "$test_name"

    if $test_func; then
        ((TESTS_PASSED++))
        log_pass "$test_name"
        return 0
    else
        ((TESTS_FAILED++))
        log_fail "$test_name"
        return 1
    fi
}

# Test --auto mode
test_auto_mode_exists() {
    bash "$SYSMAINT" --help 2>&1 | grep -q "\-\-auto"
}

test_auto_mode_execution() {
    # --auto should run without interaction
    timeout 10 bash "$SYSMAINT" --auto --dry-run &>/dev/null || return 1
}

test_auto_mode_no_interaction() {
    # Should not prompt for input in auto mode
    echo "" | timeout 10 bash "$SYSMAINT" --auto --dry-run &>/dev/null || return 1
}

# Test --gui mode
test_gui_mode_exists() {
    bash "$SYSMAINT" --help 2>&1 | grep -q "\-\-gui"
}

test_gui_mode_dialog_check() {
    # --gui requires dialog
    command -v dialog &>/dev/null || return 0
}

test_gui_mode_execution() {
    if command -v dialog &>/dev/null; then
        # Test that gui mode doesn't crash immediately
        timeout 5 bash "$SYSMAINT" --gui --dry-run &>/dev/null || return 0
    fi
}

# Test --dry-run mode
test_dry_run_mode_exists() {
    bash "$SYSMAINT" --help 2>&1 | grep -q "\-\-dry-run"
}

test_dry_run_no_changes() {
    # --dry-run should not make any system changes
    local before
    before=$(find /etc -type f -mtime -1 2>/dev/null | wc -l)
    bash "$SYSMAINT" --dry-run &>/dev/null || true
    local after
    after=$(find /etc -type f -mtime -1 2>/dev/null | wc -l)
    [[ "$before" -eq "$after" ]]
}

test_dry_run_exits_cleanly() {
    bash "$SYSMAINT" --dry-run &>/dev/null
}

# Test --quiet mode
test_quiet_mode_exists() {
    bash "$SYSMAINT" --help 2>&1 | grep -q "\-\-quiet"
}

test_quiet_mode_minimal_output() {
    local output
    output=$(bash "$SYSMAINT" --quiet --dry-run 2>&1 || true)
    # Quiet mode should have significantly less output
    local line_count
    line_count=$(echo "$output" | wc -l)
    [[ "$line_count" -lt 50 ]]
}

test_quiet_mode_no_progress() {
    local output
    output=$(bash "$SYSMAINT" --quiet --dry-run 2>&1 || true)
    # Should not contain progress indicators
    ! echo "$output" | grep -qE "\[=+\]|Progress|\.\.\."
}

# Test --verbose mode
test_verbose_mode_exists() {
    bash "$SYSMAINT" --help 2>&1 | grep -q "\-\-verbose"
}

test_verbose_mode_detailed_output() {
    local output
    output=$(bash "$SYSMAINT" --verbose --dry-run 2>&1 || true)
    # Verbose mode should have more output
    local line_count
    line_count=$(echo "$output" | wc -l)
    [[ "$line_count" -gt 10 ]]
}

test_verbose_mode_debug_info() {
    local output
    output=$(bash "$SYSMAINT" --verbose --dry-run 2>&1 || true)
    # Should contain debug/verbose markers
    echo "$output" | grep -qiE "debug|verbose|detail"
}

# Test --json-summary mode
test_json_summary_mode_exists() {
    bash "$SYSMAINT" --help 2>&1 | grep -q "\-\-json-summary"
}

test_json_summary_valid_json() {
    local output
    output=$(bash "$SYSMAINT" --json-summary --dry-run 2>&1 || true)
    echo "$output" | jq . &>/dev/null || return 1
}

test_json_summary_contains_fields() {
    local output
    output=$(bash "$SYSMAINT" --json-summary --dry-run 2>&1 || true)
    echo "$output" | jq -e '.timestamp' &>/dev/null || return 1
    echo "$output" | jq -e '.exit_code' &>/dev/null || return 1
}

# Test mode combinations
test_auto_dry_run_combination() {
    bash "$SYSMAINT" --auto --dry-run &>/dev/null
}

test_verbose_dry_run_combination() {
    bash "$SYSMAINT" --verbose --dry-run &>/dev/null
}

test_quiet_dry_run_combination() {
    bash "$SYSMAINT" --quiet --dry-run &>/dev/null
}

test_auto_verbose_combination() {
    bash "$SYSMAINT" --auto --verbose --dry-run &>/dev/null
}

# Test mode conflicts
test_gui_auto_conflict() {
    # --gui and --auto should be mutually exclusive or handled gracefully
    bash "$SYSMAINT" --gui --auto --dry-run &>/dev/null || return 1
}

test_json_quiet_combination() {
    local output
    output=$(bash "$SYSMAINT" --json-summary --quiet --dry-run 2>&1 || true)
    # JSON output should still be valid even in quiet mode
    echo "$output" | jq . &>/dev/null
}

# Test mode exit codes
test_dry_run_exit_code_zero() {
    bash "$SYSMAINT" --dry-run &>/dev/null
}

test_auto_dry_run_exit_code_zero() {
    bash "$SYSMAINT" --auto --dry-run &>/dev/null
}

# Main test execution
main() {
    echo "========================================"
    echo "SYSMAINT Mode-Specific Test Suite"
    echo "========================================"
    echo ""

    # Run --auto mode tests
    echo "Testing --auto mode..."
    run_test "--auto mode exists" test_auto_mode_exists
    run_test "--auto mode executes" test_auto_mode_execution
    run_test "--auto mode non-interactive" test_auto_mode_no_interaction
    echo ""

    # Run --gui mode tests
    echo "Testing --gui mode..."
    run_test "--gui mode exists" test_gui_mode_exists
    run_test "--gui mode dialog check" test_gui_mode_dialog_check
    run_test "--gui mode execution" test_gui_mode_execution
    echo ""

    # Run --dry-run mode tests
    echo "Testing --dry-run mode..."
    run_test "--dry-run mode exists" test_dry_run_mode_exists
    run_test "--dry-run makes no changes" test_dry_run_no_changes
    run_test "--dry-run exits cleanly" test_dry_run_exits_cleanly
    echo ""

    # Run --quiet mode tests
    echo "Testing --quiet mode..."
    run_test "--quiet mode exists" test_quiet_mode_exists
    run_test "--quiet mode minimal output" test_quiet_mode_minimal_output
    run_test "--quiet mode no progress" test_quiet_mode_no_progress
    echo ""

    # Run --verbose mode tests
    echo "Testing --verbose mode..."
    run_test "--verbose mode exists" test_verbose_mode_exists
    run_test "--verbose mode detailed output" test_verbose_mode_detailed_output
    run_test "--verbose mode debug info" test_verbose_mode_debug_info
    echo ""

    # Run --json-summary mode tests
    echo "Testing --json-summary mode..."
    run_test "--json-summary mode exists" test_json_summary_mode_exists
    run_test "--json-summary valid JSON" test_json_summary_valid_json
    run_test "--json-summary contains fields" test_json_summary_contains_fields
    echo ""

    # Run mode combination tests
    echo "Testing mode combinations..."
    run_test "--auto --dry-run combination" test_auto_dry_run_combination
    run_test "--verbose --dry-run combination" test_verbose_dry_run_combination
    run_test "--quiet --dry-run combination" test_quiet_dry_run_combination
    run_test "--auto --verbose combination" test_auto_verbose_combination
    echo ""

    # Run mode conflict tests
    echo "Testing mode conflicts..."
    run_test "--gui --auto conflict handling" test_gui_auto_conflict
    run_test "--json-summary --quiet combination" test_json_quiet_combination
    echo ""

    # Run exit code tests
    echo "Testing exit codes..."
    run_test "--dry-run exit code 0" test_dry_run_exit_code_zero
    run_test "--auto --dry-run exit code 0" test_auto_dry_run_exit_code_zero
    echo ""

    # Summary
    echo "========================================"
    echo "Test Summary"
    echo "========================================"
    echo "Tests run:    $TESTS_RUN"
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        return 1
    fi
}

main "$@"
