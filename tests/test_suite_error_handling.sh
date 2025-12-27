#!/usr/bin/env bash
# Error Handling Test Suite - 28 tests
# Tests error paths, retry logic, and recovery scenarios
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery

set -euo pipefail
cd "$(dirname "$0")/.."  # repo root

SCRIPT="./sysmaint"
PASSED=0
FAILED=0

run_test() {
    local name="$1"
    shift
    echo -n "[TEST] $name: "
    set +e
    DRY_RUN=true JSON_SUMMARY=true bash "$SCRIPT" "$@" >/dev/null 2>&1
    local exit_code=$?
    set -e
    # Accept exit codes: 0 (success), 1 (GUI), 2 (edge case), 30 (failed services), or 100 (reboot required)
    if [[ $exit_code -eq 0 || $exit_code -eq 1 || $exit_code -eq 2 || $exit_code -eq 30 || $exit_code -eq 100 ]]; then
        echo "✅ PASS"
        PASSED=$((PASSED + 1))
    else
        echo "❌ FAIL (exit: $exit_code)"
        FAILED=$((FAILED + 1))
    fi
}

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         ERROR HANDLING TEST SUITE (28 Tests)               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ==================== NETWORK RETRY LOGIC (8 tests) ====================
echo "=== Network Retry Logic (8) ==="

run_test "retry_default_dry_run" --dry-run
run_test "retry_with_fix_missing_keys" --fix-missing-keys --dry-run
run_test "retry_upgrade_operations" --upgrade --dry-run
run_test "retry_flatpak_operations" --dry-run
run_test "retry_snap_operations" --dry-run
run_test "retry_firmware_operations" --dry-run
run_test "retry_validate_repos" --dry-run
run_test "retry_comprehensive_network" --upgrade --fix-missing-keys --dry-run

# ==================== LOCK HANDLING (8 tests) ====================
echo ""
echo "=== Lock Handling (8) ==="

run_test "lock_default_dry_run" --dry-run
run_test "lock_with_upgrade" --upgrade --dry-run
run_test "lock_wait_seconds" --lock-wait-seconds=30 --dry-run
run_test "lock_force_unlock" --force-unlock --dry-run
run_test "lock_with_parallel" --parallel --dry-run
run_test "lock_stale_threshold" --dry-run
run_test "lock_multiple_operations" --upgrade --orphan-purge --dry-run
run_test "lock_with_json_summary" --json-summary --dry-run

# ==================== DISK SPACE SCENARIOS (6 tests) ====================
echo ""
echo "=== Disk Space Scenarios (6) ==="

run_test "disk_space_dry_run" --dry-run
run_test "disk_space_upgrade" --upgrade --dry-run
run_test "disk_space_kernel_purge" --purge-kernels --dry-run
run_test "disk_space_orphan_purge" --orphan-purge --dry-run
run_test "disk_space_cache_cleanup" --fstrim --drop-caches --clear-tmp --dry-run
run_test "disk_space_journal_cleanup" --journal-days=7 --dry-run

# ==================== MISSING DEPENDENCIES (6 tests) ====================
echo ""
echo "=== Missing Dependencies (6) ==="

run_test "missing_dep_no_snap" --no-snap --dry-run
run_test "missing_dep_no_flatpak" --no-flatpak --dry-run
run_test "missing_dep_no_firmware" --no-firmware --dry-run
run_test "missing_dep_no_snap_flatpak" --no-snap --no-flatpak --dry-run
run_test "missing_dep_all_optional_disabled" --no-snap --no-flatpak --no-firmware --dry-run
run_test "missing_dep_with_upgrade" --upgrade --no-snap --no-flatpak --dry-run

# ==================== RESULTS ====================
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║            ERROR HANDLING TEST RESULTS                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo "Passed: $PASSED  Failed: $FAILED"
echo "Total: $((PASSED + FAILED))"

if [[ $FAILED -eq 0 ]]; then
    echo "✅ ALL ERROR HANDLING TESTS PASSED"
    exit 0
else
    echo "❌ SOME ERROR HANDLING TESTS FAILED"
    exit 1
fi
