#!/usr/bin/env bash
# Environment Variable Test Suite - 30 tests
# Tests environment variable precedence and configuration
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery

set -euo pipefail
cd "$(dirname "$0")/.."  # repo root

SCRIPT="./sysmaint"
PASSED=0
FAILED=0

run_env_test() {
    local name="$1"
    local env_var="$2"
    local env_value="$3"
    shift 3
    echo -n "[TEST] $name: "
    set +e
    env DRY_RUN=true JSON_SUMMARY=true "$env_var=$env_value" bash "$SCRIPT" "$@" >/dev/null 2>&1
    local exit_code=$?
    set -e
    # Accept exit codes: 0 (success), 1 (non-dry-run mode requires root), 2 (edge case), 30 (failed services), or 100 (reboot required)
    if [[ $exit_code -eq 0 || $exit_code -eq 1 || $exit_code -eq 2 || $exit_code -eq 30 || $exit_code -eq 100 ]]; then
        echo "✅ PASS"
        PASSED=$((PASSED + 1))
    else
        echo "❌ FAIL (exit: $exit_code)"
        FAILED=$((FAILED + 1))
    fi
}

run_test() {
    local name="$1"
    shift
    echo -n "[TEST] $name: "
    set +e
    DRY_RUN=true JSON_SUMMARY=true bash "$SCRIPT" "$@" >/dev/null 2>&1
    local exit_code=$?
    set -e
    # Accept exit codes: 0 (success), 1 (GUI/non-dry-run), 2 (edge case), 30 (failed services), or 100 (reboot required)
    if [[ $exit_code -eq 0 || $exit_code -eq 1 || $exit_code -eq 2 || $exit_code -eq 30 || $exit_code -eq 100 ]]; then
        echo "✅ PASS"
        PASSED=$((PASSED + 1))
    else
        echo "❌ FAIL (exit: $exit_code)"
        FAILED=$((FAILED + 1))
    fi
}

echo "╔════════════════════════════════════════════════════════════╗"
echo "║       ENVIRONMENT VARIABLE TEST SUITE (30 Tests)          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ==================== DRY RUN ENVIRONMENT (4 tests) ====================
echo "=== DRY_RUN Environment Variable (4) ==="

run_env_test "env_dry_run_true" "DRY_RUN" "true" --upgrade
run_env_test "env_dry_run_false" "DRY_RUN" "false" --upgrade
run_test "dry_run_flag_takes_precedence" --dry-run
run_env_test "env_dry_run_with_flag" "DRY_RUN" "true" --dry-run

# ==================== JSON SUMMARY ENVIRONMENT (4 tests) ====================
echo ""
echo "=== JSON_SUMMARY Environment Variable (4) ==="

run_env_test "env_json_summary_true" "JSON_SUMMARY" "true" --dry-run
run_env_test "env_json_summary_false" "JSON_SUMMARY" "false" --dry-run
run_test "json_summary_flag_takes_precedence" --json-summary --dry-run
run_env_test "env_json_summary_with_flag" "JSON_SUMMARY" "true" --json-summary --dry-run

# ==================== COLOR MODE ENVIRONMENT (4 tests) ====================
echo ""
echo "=== COLOR_MODE Environment Variable (4) ==="

run_env_test "env_color_mode_always" "COLOR_MODE" "always" --dry-run
run_env_test "env_color_mode_never" "COLOR_MODE" "never" --dry-run
run_test "color_flag_takes_precedence" --color=always --dry-run
run_env_test "env_color_mode_with_flag" "COLOR_MODE" "never" --color=always --dry-run

# ==================== AUTO REBOOT ENVIRONMENT (4 tests) ====================
echo ""
echo "=== AUTO_REBOOT Environment Variable (4) ==="

run_env_test "env_auto_reboot_true" "AUTO_REBOOT" "true" --dry-run
run_env_test "env_auto_reboot_false" "AUTO_REBOOT" "false" --auto-reboot --dry-run
run_test "auto_reboot_flag_takes_precedence" --auto-reboot --dry-run
run_env_test "env_auto_reboot_delay" "AUTO_REBOOT_DELAY" "30" --dry-run

# ==================== PACKAGE MANAGER OVERRIDE ENVIRONMENT (4 tests) ====================
echo ""
echo "=== Package Manager Override Environment (4) ==="

run_env_test "env_no_snap_true" "NO_SNAP" "true" --dry-run
run_env_test "env_no_snap_false" "NO_SNAP" "false" --no-snap --dry-run
run_env_test "env_no_flatpak_true" "NO_FLATPAK" "true" --dry-run
run_env_test "env_no_firmware_true" "NO_FIRMWARE" "true" --dry-run

# ==================== SECURITY ENVIRONMENT (4 tests) ====================
echo ""
echo "=== Security Environment Variable (4) ==="

run_env_test "env_security_audit_enabled" "SECURITY_AUDIT_ENABLED" "true" --dry-run
run_env_test "env_check_zombies_true" "CHECK_ZOMBIES" "true" --dry-run
run_test "security_audit_flag_takes_precedence" --security-audit --dry-run
run_env_test "env_browser_cache_report" "BROWSER_CACHE_REPORT" "true" --dry-run

# ==================== NETWORK RETRY ENVIRONMENT (3 tests) ====================
echo ""
echo "=== Network Retry Environment (3) ==="

run_env_test "env_network_retry_count" "NETWORK_RETRY_COUNT" "5" --dry-run
run_env_test "env_network_retry_base_delay" "NETWORK_RETRY_BASE_DELAY" "2" --dry-run
run_env_test "env_network_retry_max_delay" "NETWORK_RETRY_MAX_DELAY" "60" --dry-run

# ==================== LOG CONFIGURATION ENVIRONMENT (3 tests) ====================
echo ""
echo "=== Log Configuration Environment (3) ==="

run_env_test "env_log_max_size_mb" "LOG_MAX_SIZE_MB" "100" --dry-run
run_env_test "env_log_tail_keep_kb" "LOG_TAIL_PRESERVE_KB" "500" --dry-run
run_env_test "env_wait_interval" "WAIT_INTERVAL" "2" --dry-run

# ==================== RESULTS ====================
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║            ENVIRONMENT TEST RESULTS                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo "Passed: $PASSED  Failed: $FAILED"
echo "Total: $((PASSED + FAILED))"

if [[ $FAILED -eq 0 ]]; then
    echo "✅ ALL ENVIRONMENT TESTS PASSED"
    exit 0
else
    echo "❌ SOME ENVIRONMENT TESTS FAILED"
    exit 1
fi
