#!/usr/bin/env bash
# Advanced Edge Case Tests - Complex boundary and interaction scenarios
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery

set -euo pipefail

SCRIPT="./sysmaint"
PASSED=0
FAILED=0

test_edge() {
    local name="$1"
    shift
    echo -n "  [$name] "
    if bash "$SCRIPT" "$@" >/dev/null 2>&1; then
        echo "✅"
        ((PASSED++))
    else
        echo "❌ (exit: $?)"
        ((FAILED++))
    fi
}

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ADVANCED EDGE CASES (35 Additional Tests)                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Extreme Boundary Values (7 tests)
echo "=== Extreme Boundary Values ==="
test_edge "journal-boundary-0" --journal-days=1 --dry-run
test_edge "journal-boundary-max" --journal-days=365 --dry-run
test_edge "kernel-boundary-1" --purge-kernels --keep-kernels=1 --dry-run
test_edge "kernel-boundary-10" --purge-kernels --keep-kernels=10 --dry-run
test_edge "reboot-boundary-0" --auto-reboot --auto-reboot-delay=0 --dry-run
test_edge "reboot-boundary-max" --auto-reboot --auto-reboot-delay=300 --dry-run
test_edge "journal-intermediate" --journal-days=42 --dry-run

# Multiple Same Flags (7 tests)
echo ""
echo "=== Multiple Same Flags ==="
test_edge "triple-upgrade" --upgrade --upgrade --upgrade --dry-run
test_edge "triple-security" --security-audit --security-audit --security-audit --dry-run
test_edge "triple-zombies" --check-zombies --check-zombies --check-zombies --dry-run
test_edge "quad-dryrun" --dry-run --dry-run --dry-run --dry-run
test_edge "double-purge" --purge-kernels --purge-kernels --keep-kernels=2 --dry-run
test_edge "double-orphan" --orphan-purge --orphan-purge --dry-run
test_edge "double-fstrim" --fstrim --fstrim --dry-run

# Complex Conflicts (7 tests)
echo ""
echo "=== Complex Conflicts ==="
test_edge "conflict-tmp-both" --clear-tmp-force --no-clear-tmp --dry-run
test_edge "conflict-snap-old" --no-snap-clean-old --no-snap-clean-old --dry-run
test_edge "conflict-snap-cache" --no-snap-clear-cache --no-snap-clear-cache --dry-run
test_edge "conflict-desktop-guard" --no-desktop-guard --browser-cache-purge --dry-run
test_edge "conflict-journal-multi" --journal-days=7 --journal-days=14 --dry-run
test_edge "conflict-kernel-multi" --keep-kernels=2 --keep-kernels=4 --purge-kernels --dry-run
test_edge "conflict-reboot-multi" --auto-reboot-delay=30 --auto-reboot-delay=60 --auto-reboot --dry-run

# Complex Flag Ordering (7 tests)
echo ""
echo "=== Complex Flag Ordering ==="
test_edge "order-reverse1" --dry-run --progress=dots --color=never --upgrade --security-audit
test_edge "order-reverse2" --security-audit --upgrade --color=never --progress=dots --dry-run
test_edge "order-mixed1" --upgrade --dry-run --purge-kernels --keep-kernels=3 --journal-days=7
test_edge "order-mixed2" --journal-days=7 --keep-kernels=3 --purge-kernels --dry-run --upgrade
test_edge "order-flags-first" --dry-run --color=always --progress=spinner --upgrade --security-audit --check-zombies
test_edge "order-flags-last" --upgrade --security-audit --check-zombies --dry-run --color=always --progress=spinner
test_edge "order-alternating" --upgrade --dry-run --security-audit --color=never --check-zombies --progress=quiet

# Extreme Stress Tests (7 tests)
echo ""
echo "=== Extreme Stress Tests ==="
test_edge "stress-all-features" --upgrade --purge-kernels --keep-kernels=3 --security-audit --check-zombies --browser-cache-report --browser-cache-purge --orphan-purge --fstrim --drop-caches --journal-days=7 --auto-reboot --auto-reboot-delay=30 --clear-tmp-force --no-snap-clean-old --color=always --progress=dots --dry-run
test_edge "stress-all-disabled" --no-clear-tmp --no-snap-clean-old --no-snap-clear-cache --no-desktop-guard --dry-run
test_edge "stress-all-security" --security-audit --check-zombies --upgrade --purge-kernels --orphan-purge --dry-run
test_edge "stress-all-filesystem" --fstrim --drop-caches --orphan-purge --clear-tmp-force --dry-run
test_edge "stress-all-display" --color=always --progress=spinner --dry-run
test_edge "stress-kernel-intensive" --upgrade --purge-kernels --keep-kernels=1 --auto-reboot --auto-reboot-delay=0 --dry-run
test_edge "stress-browser-intensive" --browser-cache-report --browser-cache-purge --no-desktop-guard --clear-tmp-force --dry-run

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ADVANCED EDGE CASE RESULTS                                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo "Passed: $PASSED  Failed: $FAILED"
echo "Total: $((PASSED + FAILED))"

[ $FAILED -eq 0 ] && exit 0 || exit 1
