#!/usr/bin/env bash
# Extended Smoke Tests - Additional scenarios for comprehensive validation
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery

set -euo pipefail

SCRIPT="./sysmaint"
PASSED=0
FAILED=0

run_test() {
    local name="$1"
    local args="$2"
    
    echo "[TEST] $name: $args"
    if bash "$SCRIPT" $args >/dev/null 2>&1; then
        echo "[OK] $name"
        local json_file=$(ls -t /tmp/system-maintenance/sysmaint_*.json 2>/dev/null | head -1)
        if [ -f "$json_file" ]; then
            echo "[ASSERT] summary present ($json_file)"
            ((PASSED++))
        else
            echo "[FAIL] no JSON summary"
            ((FAILED++))
        fi
    else
        echo "[FAIL] $name (exit code: $?)"
        ((FAILED++))
    fi
}

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  EXTENDED SMOKE TESTS - Additional Scenarios               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Test 1-3: Filesystem operations
run_test "fstrim" "--fstrim --dry-run"
run_test "drop-caches" "--drop-caches --dry-run"
run_test "orphan-purge" "--orphan-purge --dry-run"

# Test 4-6: Kernel management combinations
run_test "kernel-purge-keep2" "--purge-kernels --keep-kernels=2 --dry-run"
run_test "kernel-purge-keep4" "--purge-kernels --keep-kernels=4 --dry-run"
run_test "kernel-with-upgrade" "--purge-kernels --upgrade --dry-run"

# Test 7-9: Journal configurations
run_test "journal-3days" "--journal-days=3 --dry-run"
run_test "journal-7days" "--journal-days=7 --dry-run"
run_test "journal-30days" "--journal-days=30 --dry-run"

# Test 10-12: Browser cache operations
run_test "browser-report" "--browser-cache-report --dry-run"
run_test "browser-purge" "--browser-cache-purge --dry-run"
run_test "browser-both" "--browser-cache-report --browser-cache-purge --dry-run"

# Test 13-15: Snap management
run_test "snap-no-old" "--no-snap-clean-old --dry-run"
run_test "snap-no-cache" "--no-snap-clear-cache --dry-run"
run_test "snap-both-disabled" "--no-snap-clean-old --no-snap-clear-cache --dry-run"

# Test 16-18: TMP cleanup modes
run_test "tmp-default" "--dry-run"
run_test "tmp-disabled" "--no-clear-tmp --dry-run"
run_test "tmp-force" "--clear-tmp-force --dry-run"

# Test 19-21: Desktop guard scenarios
run_test "desktop-guard-on" "--dry-run"
run_test "desktop-guard-off" "--no-desktop-guard --dry-run"
run_test "desktop-with-browser" "--no-desktop-guard --browser-cache-purge --dry-run"

# Test 22-24: Auto-reboot configurations
run_test "auto-reboot-default" "--auto-reboot --dry-run"
run_test "auto-reboot-15s" "--auto-reboot --auto-reboot-delay=15 --dry-run"
run_test "auto-reboot-60s" "--auto-reboot --auto-reboot-delay=60 --dry-run"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  EXTENDED SMOKE TEST RESULTS                               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo "Passed: $PASSED  Failed assertions: $FAILED"

[ $FAILED -eq 0 ] && exit 0 || exit 1
