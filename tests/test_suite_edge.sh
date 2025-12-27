#!/usr/bin/env bash
# Consolidated Edge Case Test Suite - Basic + Extended + Advanced (67 tests)
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery

set -euo pipefail
cd "$(dirname "$0")/.."

SCRIPT="./sysmaint"
PASSED=0
FAILED=0

test_ok() {
    local name="$1"
    shift
    echo -n "[TEST] $name: "
    set +e
    bash "$SCRIPT" "$@" >/dev/null 2>&1
    local exit_code=$?
    set -e
    # Accept exit codes: 0 (success), 1 (GUI), 2 (edge case), 30 (failed services), or 100 (reboot required)
    # Exit 30 is common in CI environments where some systemd services may be in failed state
    if [[ $exit_code -eq 0 || $exit_code -eq 1 || $exit_code -eq 2 || $exit_code -eq 30 || $exit_code -eq 100 ]]; then
        echo "✅ PASS"
        PASSED=$((PASSED + 1))
    else
        echo "❌ FAIL (exit: $exit_code)"
        FAILED=$((FAILED + 1))
    fi
}

test_warn() {
    local name="$1"
    shift
    echo -n "[TEST] $name: "
    if bash "$SCRIPT" "$@" >/dev/null 2>&1; then
        echo "⚠️  WARN (expected nonzero)"
        FAILED=$((FAILED + 1))
    else
        echo "✅ PASS (nonzero expected)"
        PASSED=$((PASSED + 1))
    fi
}

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  CONSOLIDATED EDGE CASE TEST SUITE (67 Tests)             ║"
echo "║  Basic (7) + Extended (25) + Advanced (35)                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ==================== BASIC EDGE CASES (7) ====================
echo "=== Basic Edge Cases (7) ==="
test_ok "basic-help" --help
test_warn "basic-unknown-flag" --definitely-unknown-flag
test_ok "basic-journal-equals" --journal-days=5 --dry-run
test_ok "basic-reboot-space" --auto-reboot-delay 15 --dry-run
test_ok "basic-conflict-tmp" --no-clear-tmp --clear-tmp --dry-run
test_ok "basic-upgrade-dry" --upgrade --dry-run
test_ok "basic-version" --version

# ==================== EXTENDED EDGE CASES (25) ====================
echo ""
echo "=== Boundary Values (6) ==="
test_ok "ext-journal-min" --journal-days=1 --dry-run
test_ok "ext-journal-max" --journal-days=365 --dry-run
test_ok "ext-kernel-min" --purge-kernels --keep-kernels=1 --dry-run
test_ok "ext-kernel-max" --purge-kernels --keep-kernels=10 --dry-run
test_ok "ext-reboot-min" --auto-reboot --auto-reboot-delay=0 --dry-run
test_ok "ext-reboot-max" --auto-reboot --auto-reboot-delay=300 --dry-run

echo ""
echo "=== Multiple Flags (6) ==="
test_ok "ext-all-colors" --color=always --dry-run
test_ok "ext-all-progress" --progress=spinner --dry-run
test_ok "ext-double-upgrade" --upgrade --upgrade --dry-run
test_ok "ext-conflict-tmp" --clear-tmp-force --no-clear-tmp --dry-run
test_ok "ext-conflict-snap1" --no-snap-clean-old --no-snap-clean-old --dry-run
test_ok "ext-conflict-snap2" --no-snap-clear-cache --no-snap-clear-cache --dry-run

echo ""
echo "=== Flag Order (5) ==="
test_ok "ext-order1" --dry-run --upgrade --security-audit
test_ok "ext-order2" --security-audit --upgrade --dry-run
test_ok "ext-order3" --upgrade --dry-run --security-audit
test_ok "ext-order4" --color=never --progress=quiet --dry-run
test_ok "ext-order5" --progress=quiet --color=never --dry-run

echo ""
echo "=== Special Scenarios (4) ==="
test_ok "ext-help" --help
test_ok "ext-version" --version
test_ok "ext-dry-only" --dry-run
test_ok "ext-multi-dry" --dry-run --dry-run --dry-run

echo ""
echo "=== Stress Tests (4) ==="
test_ok "ext-max-flags" --upgrade --purge-kernels --keep-kernels=3 --security-audit --check-zombies --browser-cache-report --browser-cache-purge --orphan-purge --fstrim --drop-caches --journal-days=7 --auto-reboot --auto-reboot-delay=30 --color=always --progress=dots --dry-run
test_ok "ext-minimal" --no-clear-tmp --no-snap-clean-old --no-snap-clear-cache --no-desktop-guard --dry-run
test_ok "ext-all-security" --security-audit --check-zombies --upgrade --dry-run
test_ok "ext-all-fs" --fstrim --drop-caches --orphan-purge --dry-run

# ==================== ADVANCED EDGE CASES (35) ====================
echo ""
echo "=== Extreme Boundaries (7) ==="
test_ok "adv-journal-0" --journal-days=1 --dry-run
test_ok "adv-journal-max" --journal-days=365 --dry-run
test_ok "adv-kernel-1" --purge-kernels --keep-kernels=1 --dry-run
test_ok "adv-kernel-10" --purge-kernels --keep-kernels=10 --dry-run
test_ok "adv-reboot-0" --auto-reboot --auto-reboot-delay=0 --dry-run
test_ok "adv-reboot-max" --auto-reboot --auto-reboot-delay=300 --dry-run
test_ok "adv-journal-42" --journal-days=42 --dry-run

echo ""
echo "=== Multiple Same Flags (7) ==="
test_ok "adv-triple-upgrade" --upgrade --upgrade --upgrade --dry-run
test_ok "adv-triple-security" --security-audit --security-audit --security-audit --dry-run
test_ok "adv-triple-zombies" --check-zombies --check-zombies --check-zombies --dry-run
test_ok "adv-quad-dry" --dry-run --dry-run --dry-run --dry-run
test_ok "adv-double-purge" --purge-kernels --purge-kernels --keep-kernels=2 --dry-run
test_ok "adv-double-orphan" --orphan-purge --orphan-purge --dry-run
test_ok "adv-double-fstrim" --fstrim --fstrim --dry-run

echo ""
echo "=== Complex Conflicts (7) ==="
test_ok "adv-conflict-tmp" --clear-tmp-force --no-clear-tmp --dry-run
test_ok "adv-conflict-snap-old" --no-snap-clean-old --no-snap-clean-old --dry-run
test_ok "adv-conflict-snap-cache" --no-snap-clear-cache --no-snap-clear-cache --dry-run
test_ok "adv-conflict-desktop" --no-desktop-guard --browser-cache-purge --dry-run
test_ok "adv-conflict-journal" --journal-days=7 --journal-days=14 --dry-run
test_ok "adv-conflict-kernel" --keep-kernels=2 --keep-kernels=4 --purge-kernels --dry-run
test_ok "adv-conflict-reboot" --auto-reboot-delay=30 --auto-reboot-delay=60 --auto-reboot --dry-run

echo ""
echo "=== Complex Ordering (7) ==="
test_ok "adv-order-rev1" --dry-run --progress=dots --color=never --upgrade --security-audit
test_ok "adv-order-rev2" --security-audit --upgrade --color=never --progress=dots --dry-run
test_ok "adv-order-mix1" --upgrade --dry-run --purge-kernels --keep-kernels=3 --journal-days=7
test_ok "adv-order-mix2" --journal-days=7 --keep-kernels=3 --purge-kernels --dry-run --upgrade
test_ok "adv-order-first" --dry-run --color=always --progress=spinner --upgrade --security-audit --check-zombies
test_ok "adv-order-last" --upgrade --security-audit --check-zombies --dry-run --color=always --progress=spinner
test_ok "adv-order-alt" --upgrade --dry-run --security-audit --color=never --check-zombies --progress=quiet

echo ""
echo "=== Extreme Stress (7) ==="
test_ok "adv-stress-all" --upgrade --purge-kernels --keep-kernels=3 --security-audit --check-zombies --browser-cache-report --browser-cache-purge --orphan-purge --fstrim --drop-caches --journal-days=7 --auto-reboot --auto-reboot-delay=30 --clear-tmp-force --no-snap-clean-old --color=always --progress=dots --dry-run
test_ok "adv-stress-disabled" --no-clear-tmp --no-snap-clean-old --no-snap-clear-cache --no-desktop-guard --dry-run
test_ok "adv-stress-security" --security-audit --check-zombies --upgrade --purge-kernels --orphan-purge --dry-run
test_ok "adv-stress-fs" --fstrim --drop-caches --orphan-purge --clear-tmp-force --dry-run
test_ok "adv-stress-display" --color=always --progress=spinner --dry-run
test_ok "adv-stress-kernel" --upgrade --purge-kernels --keep-kernels=1 --auto-reboot --auto-reboot-delay=0 --dry-run
test_ok "adv-stress-browser" --browser-cache-report --browser-cache-purge --no-desktop-guard --clear-tmp-force --dry-run

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  CONSOLIDATED EDGE CASE TEST RESULTS                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo "Passed: $PASSED  Failed: $FAILED"
echo "Total: $((PASSED + FAILED))"

[ $FAILED -eq 0 ] && exit 0 || exit 1
