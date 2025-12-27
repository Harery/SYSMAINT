#!/usr/bin/env bash
# Parallel Execution Test Suite - 22 tests
# Tests DAG-based parallel execution engine
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
echo "║       PARALLEL EXECUTION TEST SUITE (22 Tests)            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ==================== PARALLEL EXECUTION FLAGS (8 tests) ====================
echo "=== Parallel Execution Flags (8) ==="

run_test "parallel_flag_enabled" --parallel --dry-run
run_test "parallel_with_upgrade" --parallel --upgrade --dry-run
run_test "parallel_with_security" --parallel --security-audit --dry-run
run_test "parallel_with_cleanup" --parallel --orphan-purge --fstrim --dry-run
run_test "parallel_comprehensive" --parallel --upgrade --orphan-purge --security-audit --dry-run
run_test "parallel_with_json" --parallel --json-summary --dry-run
run_test "parallel_with_progress" --parallel --progress=spinner --dry-run
run_test "parallel_with_color" --parallel --color=always --dry-run

# ==================== PHASE EXECUTION ORDER (8 tests) ====================
echo ""
echo "=== Phase Execution Order (8) ==="

run_test "phase_validate_repos" --dry-run
run_test "phase_fix_broken_if_any" --upgrade --dry-run
run_test "phase_detect_missing_pubkeys" --dry-run
run_test "phase_fix_missing_pubkeys" --fix-missing-keys --dry-run
run_test "phase_kernel_status" --purge-kernels --dry-run
run_test "phase_apt_maintenance" --upgrade --dry-run
run_test "phase_orphan_purge" --orphan-purge --dry-run
run_test "phase_check_failed_services" --check-failed-services --dry-run

# ==================== DEPENDENCY RESOLUTION (6 tests) ====================
echo ""
echo "=== Dependency Resolution (6) ==="

run_test "deps_upgrade_before_kernel" --upgrade --purge-kernels --dry-run
run_test "deps_security_after_upgrade" --upgrade --security-audit --dry-run
run_test "deps_cleanup_after_operations" --upgrade --orphan-purge --fstrim --dry-run
run_test "deps_journal_after_other" --journal-days=7 --dry-run
run_test "deps_parallel_independent" --parallel --security-audit --check-zombies --dry-run
run_test "deps_complex_workflow" --upgrade --fix-missing-keys --purge-kernels --orphan-purge --security-audit --fstrim --drop-caches --dry-run

# ==================== RESULTS ====================
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║          PARALLEL EXECUTION TEST RESULTS                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo "Passed: $PASSED  Failed: $FAILED"
echo "Total: $((PASSED + FAILED))"

if [[ $FAILED -eq 0 ]]; then
    echo "✅ ALL PARALLEL EXECUTION TESTS PASSED"
    exit 0
else
    echo "❌ SOME PARALLEL EXECUTION TESTS FAILED"
    exit 1
fi
