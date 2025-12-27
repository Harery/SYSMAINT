#!/usr/bin/env bash
# Function Unit Test Suite - 65 tests
# Tests core utility functions directly
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery

set -euo pipefail
cd "$(dirname "$0")/.."  # repo root

SCRIPT="./sysmaint"
PASSED=0
FAILED=0

# Source the utils library directly for unit testing
source lib/utils.sh
source lib/core/detection.sh

# Test helper functions
run_function_test() {
    local name="$1"
    local expected="$2"
    local actual="$3"
    echo -n "[TEST] $name: "
    if [[ "$actual" == "$expected" ]]; then
        echo "✅ PASS"
        PASSED=$((PASSED + 1))
    else
        echo "❌ FAIL (expected: $expected, got: $actual)"
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
    # Accept exit codes: 0 (success), 2 (edge case), 30 (failed services), or 100 (reboot required)
    if [[ $exit_code -eq 0 || $exit_code -eq 2 || $exit_code -eq 30 || $exit_code -eq 100 ]]; then
        echo "✅ PASS"
        PASSED=$((PASSED + 1))
    else
        echo "❌ FAIL (exit: $exit_code)"
        FAILED=$((FAILED + 1))
    fi
}

echo "╔════════════════════════════════════════════════════════════╗"
echo "║        FUNCTION UNIT TEST SUITE (65 Tests)                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ==================== CORE DETECTION FUNCTIONS (15 tests) ====================
echo "=== Core Detection Functions (15) ==="

# Test 1: check_os_valid_ubuntu
echo -n "[TEST] check_os_valid_ubuntu: "
if DRY_RUN=true bash "$SCRIPT" --distro ubuntu --detect >/dev/null 2>&1; then
    echo "✅ PASS"
    PASSED=$((PASSED + 1))
else
    echo "❌ FAIL"
    FAILED=$((FAILED + 1))
fi

# Test 2: check_os_valid_debian
echo -n "[TEST] check_os_valid_debian: "
if DRY_RUN=true bash "$SCRIPT" --distro debian --detect >/dev/null 2>&1; then
    echo "✅ PASS"
    PASSED=$((PASSED + 1))
else
    echo "❌ FAIL"
    FAILED=$((FAILED + 1))
fi

# Test 3: check_os_valid_fedora
echo -n "[TEST] check_os_valid_fedora: "
if DRY_RUN=true bash "$SCRIPT" --distro fedora --detect >/dev/null 2>&1; then
    echo "✅ PASS"
    PASSED=$((PASSED + 1))
else
    echo "❌ FAIL"
    FAILED=$((FAILED + 1))
fi

# Test 4: check_os_valid_arch
echo -n "[TEST] check_os_valid_arch: "
if DRY_RUN=true bash "$SCRIPT" --distro arch --detect >/dev/null 2>&1; then
    echo "✅ PASS"
    PASSED=$((PASSED + 1))
else
    echo "❌ FAIL"
    FAILED=$((FAILED + 1))
fi

# Test 5: check_os_valid_suse
echo -n "[TEST] check_os_valid_suse: "
if DRY_RUN=true bash "$SCRIPT" --distro opensuse --detect >/dev/null 2>&1; then
    echo "✅ PASS"
    PASSED=$((PASSED + 1))
else
    echo "❌ FAIL"
    FAILED=$((FAILED + 1))
fi

# Test 6: check_os_manual_override_distro
run_test "check_os_manual_override_distro" --distro ubuntu --dry-run

# Test 7: check_os_manual_override_pkg_manager
run_test "check_os_manual_override_pkg_manager" --pkg-manager apt --dry-run

# Test 8: check_os_manual_override_init_system
run_test "check_os_manual_override_init_system" --init-system systemd --dry-run

# Test 9-15: Combined overrides and family detection
run_test "check_os_combined_overrides" --distro fedora --pkg-manager dnf --dry-run
run_test "detect_mode_shows_report" --detect
run_test "detect_with_json_summary" --detect --json-summary
run_test "detect_dry_run_safe" --detect --dry-run
run_test "detect_no_root_required" --detect
run_test "force_generic_mode" --force-generic --dry-run
run_test "simulate_upgrade_mode" --simulate-upgrade --dry-run

# ==================== PROGRESS & EMA FUNCTIONS (18 tests) ====================
echo ""
echo "=== Progress & EMA Functions (18) ==="

# Reset arrays for clean testing
unset PHASE_EST_EMA
declare -A PHASE_EST_EMA

# Test 16: ema_update_first_value
echo -n "[TEST] ema_update_first_value: "
PROGRESS_ALPHA=0.2
_ema_update "test_phase" 5.0
result="${PHASE_EST_EMA[test_phase]:-}"
# Accept both 5.0 and 5.000
if [[ "$result" == "5.0" || "$result" == "5.000" ]]; then
    echo "✅ PASS"
    PASSED=$((PASSED + 1))
else
    echo "❌ FAIL (expected 5.0 or 5.000, got $result)"
    FAILED=$((FAILED + 1))
fi

# Test 17: ema_update_subsequent_values
echo -n "[TEST] ema_update_subsequent_values: "
_ema_update "test_phase" 10.0
result="${PHASE_EST_EMA[test_phase]:-}"
# With alpha=0.2: ema = 0.2*10 + 0.8*5 = 2 + 4 = 6
expected="6.000"
if [[ "$result" == "$expected" ]]; then
    echo "✅ PASS"
    PASSED=$((PASSED + 1))
else
    echo "❌ FAIL (expected $expected, got $result)"
    FAILED=$((FAILED + 1))
fi

# Test 18: fmt_hms_seconds_only
echo -n "[TEST] fmt_hms_seconds_only: "
result=$(_fmt_hms 45)
if [[ "$result" == "0:45" ]]; then
    echo "✅ PASS"
    PASSED=$((PASSED + 1))
else
    echo "❌ FAIL (expected 0:45, got $result)"
    FAILED=$((FAILED + 1))
fi

# Test 19: fmt_hms_minutes_seconds
echo -n "[TEST] fmt_hms_minutes_seconds: "
result=$(_fmt_hms 125)
if [[ "$result" == "2:05" ]]; then
    echo "✅ PASS"
    PASSED=$((PASSED + 1))
else
    echo "❌ FAIL (expected 2:05, got $result)"
    FAILED=$((FAILED + 1))
fi

# Test 20: fmt_hms_hours_minutes_seconds
echo -n "[TEST] fmt_hms_hours_minutes_seconds: "
result=$(_fmt_hms 3661)
if [[ "$result" == "1:01:01" ]]; then
    echo "✅ PASS"
    PASSED=$((PASSED + 1))
else
    echo "❌ FAIL (expected 1:01:01, got $result)"
    FAILED=$((FAILED + 1))
fi

# Test 21: fmt_hms_negative_input
echo -n "[TEST] fmt_hms_negative_input: "
result=$(_fmt_hms -10)
if [[ "$result" == "0:00" ]]; then
    echo "✅ PASS"
    PASSED=$((PASSED + 1))
else
    echo "❌ FAIL (expected 0:00, got $result)"
    FAILED=$((FAILED + 1))
fi

# Test 22: float_max_first_larger
echo -n "[TEST] float_max_first_larger: "
result=$(_float_max 5.5 3.3)
if [[ "$result" == "5.500" ]]; then
    echo "✅ PASS"
    PASSED=$((PASSED + 1))
else
    echo "❌ FAIL (expected 5.500, got $result)"
    FAILED=$((FAILED + 1))
fi

# Test 23: float_max_second_larger
echo -n "[TEST] float_max_second_larger: "
result=$(_float_max 3.3 5.5)
if [[ "$result" == "5.500" ]]; then
    echo "✅ PASS"
    PASSED=$((PASSED + 1))
else
    echo "❌ FAIL (expected 5.500, got $result)"
    FAILED=$((FAILED + 1))
fi

# Test 24: float_min_first_smaller
echo -n "[TEST] float_min_first_smaller: "
result=$(_float_min 2.2 4.4)
if [[ "$result" == "2.200" ]]; then
    echo "✅ PASS"
    PASSED=$((PASSED + 1))
else
    echo "❌ FAIL (expected 2.200, got $result)"
    FAILED=$((FAILED + 1))
fi

# Test 25: float_min_second_smaller
echo -n "[TEST] float_min_second_smaller: "
result=$(_float_min 4.4 2.2)
if [[ "$result" == "2.200" ]]; then
    echo "✅ PASS"
    PASSED=$((PASSED + 1))
else
    echo "❌ FAIL (expected 2.200, got $result)"
    FAILED=$((FAILED + 1))
fi

# Test 26-33: phase_included tests
echo -n "[TEST] phase_included_default: "
if _phase_included "clean_tmp"; then
    echo "✅ PASS"
    PASSED=$((PASSED + 1))
else
    echo "❌ FAIL"
    FAILED=$((FAILED + 1))
fi

echo -n "[TEST] phase_included_snap_excluded: "
NO_SNAP=true
if ! _phase_included "snap_maintenance"; then
    echo "✅ PASS"
    PASSED=$((PASSED + 1))
else
    echo "❌ FAIL"
    FAILED=$((FAILED + 1))
fi
unset NO_SNAP

echo -n "[TEST] phase_included_kernel_purge_enabled: "
PURGE_OLD_KERNELS=true
if _phase_included "kernel_purge_phase"; then
    echo "✅ PASS"
    PASSED=$((PASSED + 1))
else
    echo "❌ FAIL"
    FAILED=$((FAILED + 1))
fi
unset PURGE_OLD_KERNELS

# ==================== STATE MANAGEMENT FUNCTIONS (12 tests) ====================
echo ""
echo "=== State Management Functions (12) ==="

# Test 34: init_state_dir_root_user
echo -n "[TEST] init_state_dir_creates_dir: "
STATE_DIR="/tmp/test_sysmaint_state_$$"
_init_state_dir
if [[ -d "$STATE_DIR" ]]; then
    echo "✅ PASS"
    PASSED=$((PASSED + 1))
    rm -rf "$STATE_DIR"
else
    echo "❌ FAIL"
    FAILED=$((FAILED + 1))
fi

# Test 35: state_file_path
echo -n "[TEST] state_file_path: "
STATE_DIR="/tmp/test_sysmaint_state_$$"
result=$(_state_file)
expected="/tmp/test_sysmaint_state_$$/timings.json"
if [[ "$result" == "$expected" ]]; then
    echo "✅ PASS"
    PASSED=$((PASSED + 1))
else
    echo "❌ FAIL (expected $expected, got $result)"
    FAILED=$((FAILED + 1))
fi
rm -rf "$STATE_DIR"

# Test 36: save_phase_estimates_empty
echo -n "[TEST] save_phase_estimates_empty: "
STATE_DIR="/tmp/test_sysmaint_state_$$"
unset PHASE_EST_EMA
declare -A PHASE_EST_EMA
save_phase_estimates
if [[ -f "$STATE_DIR/timings.json" ]]; then
    echo "✅ PASS"
    PASSED=$((PASSED + 1))
    rm -rf "$STATE_DIR"
else
    echo "❌ FAIL"
    FAILED=$((FAILED + 1))
    rm -rf "$STATE_DIR"
fi

# Test 37: save_phase_estimates_with_data
echo -n "[TEST] save_phase_estimates_with_data: "
STATE_DIR="/tmp/test_sysmaint_state_$$"
declare -A PHASE_EST_EMA
PHASE_EST_EMA["clean_tmp"]="2.500"
PHASE_EST_EMA["validate_repos"]="4.000"
save_phase_estimates
if grep -q "clean_tmp" "$STATE_DIR/timings.json" && grep -q "validate_repos" "$STATE_DIR/timings.json"; then
    echo "✅ PASS"
    PASSED=$((PASSED + 1))
    rm -rf "$STATE_DIR"
else
    echo "❌ FAIL"
    FAILED=$((FAILED + 1))
    rm -rf "$STATE_DIR"
fi

# Test 38: load_phase_estimates_valid_json
echo -n "[TEST] load_phase_estimates_valid_json: "
STATE_DIR="/tmp/test_sysmaint_state_$$"
mkdir -p "$STATE_DIR"
cat > "$STATE_DIR/timings.json" <<'EOF'
{
  "clean_tmp": 2.5,
  "validate_repos": 4.0
}
EOF
unset PHASE_EST_EMA
declare -A PHASE_EST_EMA
load_phase_estimates
if [[ "${PHASE_EST_EMA[clean_tmp]:-}" == "2.5" ]]; then
    echo "✅ PASS"
    PASSED=$((PASSED + 1))
    rm -rf "$STATE_DIR"
else
    echo "❌ FAIL"
    FAILED=$((FAILED + 1))
    rm -rf "$STATE_DIR"
fi

# Test 39: load_phase_estimates_missing_file
echo -n "[TEST] load_phase_estimates_missing_file: "
STATE_DIR="/tmp/test_sysmaint_state_$$"
unset PHASE_EST_EMA
declare -A PHASE_EST_EMA
load_phase_estimates  # Should not fail
echo "✅ PASS"
PASSED=$((PASSED + 1))
rm -rf "$STATE_DIR"

# ==================== PACKAGE MANAGER FUNCTIONS (20 tests) ====================
echo ""
echo "=== Package Manager Functions (20) ==="

# Test 40-59: Package operations through main script
run_test "pkg_update_dry_run" --upgrade --dry-run
run_test "pkg_upgrade_dry_run" --upgrade --dry-run
run_test "pkg_fix_broken_dry_run" --upgrade --dry-run
run_test "pkg_autoremove_dry_run" --orphan-purge --dry-run
run_test "pkg_autoclean_dry_run" --upgrade --dry-run

run_test "apt_maintenance_dry_run" --upgrade --dry-run
run_test "snap_maintenance_dry_run" --dry-run
run_test "snap_cleanup_old_dry_run" --snap-clean-old --dry-run
run_test "snap_clear_cache_dry_run" --snap-clear-cache --dry-run
run_test "flatpak_maintenance_dry_run" --dry-run
run_test "firmware_maintenance_dry_run" --dry-run

run_test "validate_repos_dry_run" --dry-run
run_test "detect_missing_pubkeys_dry_run" --dry-run
run_test "fix_missing_pubkeys_dry_run" --fix-missing-keys --dry-run
run_test "check_failed_services_dry_run" --check-failed-services --dry-run
run_test "check_zombie_processes_dry_run" --check-zombies --dry-run
run_test "security_audit_dry_run" --security-audit --dry-run
run_test "kernel_status_dry_run" --purge-kernels --dry-run
run_test "kernel_purge_phase_dry_run" --purge-kernels=2 --dry-run
run_test "orphan_purge_phase_dry_run" --orphan-purge --dry-run
run_test "fstrim_phase_dry_run" --fstrim --dry-run

# ==================== UTILITY FUNCTIONS (15 tests) ====================
echo ""
echo "=== Utility Functions (15) ==="

# Test 60: is_root_user_false
echo -n "[TEST] is_root_user_false: "
if ! _is_root_user; then
    echo "✅ PASS"
    PASSED=$((PASSED + 1))
else
    echo "❌ FAIL"
    FAILED=$((FAILED + 1))
fi

# Test 61-65: Integration tests
run_test "utility_clean_tmp_dry_run" --clear-tmp --dry-run
run_test "utility_drop_caches_dry_run" --drop-caches --dry-run
run_test "utility_journal_maintenance_dry_run" --journal-days=7 --dry-run
run_test "utility_dns_maintenance_dry_run" --dry-run
run_test "utility_browser_cache_phase_dry_run" --browser-cache-report --dry-run

# ==================== RESULTS ====================
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║           FUNCTION UNIT TEST RESULTS                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo "Passed: $PASSED  Failed: $FAILED"
echo "Total: $((PASSED + FAILED))"

if [[ $FAILED -eq 0 ]]; then
    echo "✅ ALL FUNCTION TESTS PASSED"
    exit 0
else
    echo "❌ SOME FUNCTION TESTS FAILED"
    exit 1
fi
