#!/usr/bin/env bash
# Ultra-Extended Smoke Tests - Additional advanced scenarios
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery

set -euo pipefail

SCRIPT="./sysmaint"
PASSED=0
FAILED=0

run_test() {
    local name="$1"
    shift
    echo -n "[TEST] $name: "
    if bash "$SCRIPT" "$@" >/dev/null 2>&1; then
        echo "✅ PASS"
        ((PASSED++))
    else
        echo "❌ FAIL (exit: $?)"
        ((FAILED++))
    fi
}

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ULTRA-EXTENDED SMOKE TESTS (30 Additional Tests)         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Advanced Filesystem Operations (5 tests)
echo "=== Advanced Filesystem Operations ==="
run_test "fs-all-ops" --fstrim --drop-caches --orphan-purge --dry-run
run_test "fs-trim-only" --fstrim --no-clear-tmp --dry-run
run_test "fs-drop-only" --drop-caches --no-snap-clean-old --dry-run
run_test "fs-orphan-only" --orphan-purge --no-snap-clear-cache --dry-run
run_test "fs-none" --no-clear-tmp --no-snap-clean-old --no-snap-clear-cache --dry-run

# Advanced Kernel Scenarios (5 tests)
echo ""
echo "=== Advanced Kernel Scenarios ==="
run_test "kernel-keep1-aggressive" --purge-kernels --keep-kernels=1 --upgrade --dry-run
run_test "kernel-keep5-conservative" --purge-kernels --keep-kernels=5 --dry-run
run_test "kernel-keep3-reboot" --purge-kernels --keep-kernels=3 --auto-reboot --dry-run
run_test "kernel-no-purge-upgrade" --upgrade --dry-run
run_test "kernel-purge-security" --purge-kernels --security-audit --dry-run

# Advanced Journal Policies (5 tests)
echo ""
echo "=== Advanced Journal Policies ==="
run_test "journal-1day" --journal-days=1 --dry-run
run_test "journal-14days" --journal-days=14 --dry-run
run_test "journal-21days" --journal-days=21 --dry-run
run_test "journal-60days" --journal-days=60 --dry-run
run_test "journal-90days" --journal-days=90 --dry-run

# Advanced Browser Workflows (5 tests)
echo ""
echo "=== Advanced Browser Workflows ==="
run_test "browser-desktop-report" --browser-cache-report --no-desktop-guard --dry-run
run_test "browser-desktop-purge" --browser-cache-purge --no-desktop-guard --dry-run
run_test "browser-guard-report" --browser-cache-report --dry-run
run_test "browser-guard-purge" --browser-cache-purge --dry-run
run_test "browser-all-no-guard" --browser-cache-report --browser-cache-purge --no-desktop-guard --dry-run

# Advanced Security Workflows (5 tests)
echo ""
echo "=== Advanced Security Workflows ==="
run_test "security-full-stack" --security-audit --check-zombies --upgrade --purge-kernels --dry-run
run_test "security-audit-only" --security-audit --no-clear-tmp --dry-run
run_test "security-zombies-only" --check-zombies --no-snap-clean-old --dry-run
run_test "security-upgrade-audit" --upgrade --security-audit --dry-run
run_test "security-all-no-upgrade" --security-audit --check-zombies --dry-run

# Advanced Display Combinations (5 tests)
echo ""
echo "=== Advanced Display Combinations ==="
run_test "display-always-spinner" --color=always --progress=spinner --dry-run
run_test "display-never-dots" --color=never --progress=dots --dry-run
run_test "display-auto-quiet" --color=auto --progress=quiet --dry-run
run_test "display-always-quiet" --color=always --progress=quiet --dry-run
run_test "display-never-spinner" --color=never --progress=spinner --dry-run

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ULTRA-EXTENDED SMOKE RESULTS                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo "Passed: $PASSED  Failed: $FAILED"
echo "Total: $((PASSED + FAILED))"

[ $FAILED -eq 0 ] && exit 0 || exit 1
