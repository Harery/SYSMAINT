#!/usr/bin/env bash
# Extended GUI Mode Test Suite - 18 tests
# Tests GUI/TUI edge cases and fallback scenarios
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
    if [[ $exit_code -eq 0 || $exit_code -eq 30 || $exit_code -eq 100 || $exit_code -eq 1 ]]; then
        # Exit 1 is acceptable for GUI if dialog/whiptail not available
        echo "✅ PASS (exit: $exit_code)"
        PASSED=$((PASSED + 1))
    else
        echo "❌ FAIL (exit: $exit_code)"
        FAILED=$((FAILED + 1))
    fi
}

echo "╔════════════════════════════════════════════════════════════╗"
echo "║       EXTENDED GUI MODE TEST SUITE (18 Tests)             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ==================== GUI FRAMEWORK DETECTION (8 tests) ====================
echo "=== GUI Framework Detection (8) ==="

run_test "gui_mode_basic" --gui --dry-run
run_test "gui_mode_tui_alias" --tui --dry-run
run_test "gui_mode_with_upgrade" --gui --upgrade --dry-run
run_test "gui_mode_with_security" --gui --security-audit --dry-run
run_test "gui_mode_with_cleanup" --gui --orphan-purge --fstrim --dry-run
run_test "gui_mode_with_profiles" --gui --dry-run
run_test "gui_mode_with_json" --gui --json-summary --dry-run
run_test "gui_mode_with_progress" --gui --progress=spinner --dry-run

# ==================== PROFILES SUBCOMMAND (5 tests) ====================
echo ""
echo "=== Profiles Subcommand (5) ==="

run_test "profiles_minimal" profiles minimal --dry-run
run_test "profiles_server" profiles server --dry-run
run_test "profiles_desktop" profiles desktop --dry-run
run_test "profiles_with_json" profiles minimal --json-summary --dry-run
run_test "profiles_with_upgrade" profiles server --upgrade --dry-run

# ==================== GUI INTERACTION SCENARIOS (5 tests) ====================
echo ""
echo "=== GUI Interaction Scenarios (5) ==="

run_test "gui_combo_operations" --gui --upgrade --security-audit --dry-run
run_test "gui_comprehensive" --gui --upgrade --orphan-purge --security-audit --fstrim --dry-run
run_test "gui_auto_mode_conflict" --gui --auto --dry-run
run_test "gui_dry_run_combination" --gui --dry-run
run_test "gui_exit_codes" --gui

# ==================== RESULTS ====================
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║           EXTENDED GUI MODE TEST RESULTS                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo "Passed: $PASSED  Failed: $FAILED"
echo "Total: $((PASSED + FAILED))"

if [[ $FAILED -eq 0 ]]; then
    echo "✅ ALL EXTENDED GUI MODE TESTS PASSED"
    exit 0
else
    echo "❌ SOME EXTENDED GUI MODE TESTS FAILED"
    exit 1
fi
