#!/usr/bin/env bash
# Advanced Feature Combination Tests - Complex multi-feature interactions
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery

set -euo pipefail

SCRIPT="./sysmaint"
PASSED=0
FAILED=0

test_combo() {
    local name="$1"
    shift
    echo -n "  [$name] "
    if bash "$SCRIPT" "$@" >/dev/null 2>&1; then
        echo "✅"
        ((PASSED++))
    else
        echo "❌"
        ((FAILED++))
    fi
}

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ADVANCED FEATURE COMBINATIONS (40 Tests)                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Triple Feature Combinations (8 tests)
echo "=== Triple Feature Combinations ==="
test_combo "triple-upgrade-kernel-journal" --upgrade --purge-kernels --keep-kernels=3 --journal-days=7 --dry-run
test_combo "triple-security-browser-zombies" --security-audit --browser-cache-report --check-zombies --dry-run
test_combo "triple-fs-orphan-fstrim" --fstrim --orphan-purge --drop-caches --dry-run
test_combo "triple-display-color-progress" --color=always --progress=spinner --upgrade --dry-run
test_combo "triple-snap-tmp-desktop" --no-snap-clean-old --no-clear-tmp --no-desktop-guard --dry-run
test_combo "triple-journal-kernel-reboot" --journal-days=14 --purge-kernels --auto-reboot --dry-run
test_combo "triple-browser-security-upgrade" --browser-cache-purge --security-audit --upgrade --dry-run
test_combo "triple-fs-journal-kernel" --fstrim --journal-days=7 --purge-kernels --dry-run

# Quad Feature Combinations (8 tests)
echo ""
echo "=== Quad Feature Combinations ==="
test_combo "quad-full-maintenance" --upgrade --purge-kernels --orphan-purge --journal-days=7 --dry-run
test_combo "quad-security-stack" --security-audit --check-zombies --upgrade --browser-cache-report --dry-run
test_combo "quad-filesystem-ops" --fstrim --drop-caches --orphan-purge --clear-tmp-force --dry-run
test_combo "quad-display-modes" --color=never --progress=quiet --upgrade --security-audit --dry-run
test_combo "quad-desktop-full" --browser-cache-report --browser-cache-purge --check-zombies --journal-days=3 --dry-run
test_combo "quad-server-full" --no-desktop-guard --fstrim --journal-days=14 --purge-kernels --dry-run
test_combo "quad-automated" --progress=quiet --color=never --upgrade --journal-days=7 --dry-run
test_combo "quad-reboot-stack" --auto-reboot --auto-reboot-delay=45 --upgrade --purge-kernels --dry-run

# Penta Feature Combinations (8 tests)
echo ""
echo "=== Penta Feature Combinations ==="
test_combo "penta-super-clean" --upgrade --purge-kernels --orphan-purge --clear-tmp-force --journal-days=7 --dry-run
test_combo "penta-security-max" --security-audit --check-zombies --upgrade --purge-kernels --browser-cache-report --dry-run
test_combo "penta-fs-intensive" --fstrim --drop-caches --orphan-purge --clear-tmp-force --journal-days=3 --dry-run
test_combo "penta-desktop-max" --browser-cache-report --browser-cache-purge --check-zombies --journal-days=3 --upgrade --dry-run
test_combo "penta-server-max" --no-desktop-guard --fstrim --drop-caches --journal-days=14 --purge-kernels --dry-run
test_combo "penta-reboot-full" --auto-reboot --auto-reboot-delay=30 --upgrade --purge-kernels --journal-days=7 --dry-run
test_combo "penta-display-full" --color=always --progress=dots --upgrade --security-audit --check-zombies --dry-run
test_combo "penta-snap-control" --no-snap-clean-old --no-snap-clear-cache --no-clear-tmp --no-desktop-guard --journal-days=7 --dry-run

# Hexa+ Feature Combinations (8 tests)
echo ""
echo "=== Hexa+ Feature Combinations ==="
test_combo "hexa-ultra-clean" --upgrade --purge-kernels --keep-kernels=2 --orphan-purge --fstrim --clear-tmp-force --journal-days=7 --dry-run
test_combo "hexa-max-security" --security-audit --check-zombies --upgrade --purge-kernels --browser-cache-report --journal-days=7 --dry-run
test_combo "hexa-fs-max" --fstrim --drop-caches --orphan-purge --clear-tmp-force --journal-days=3 --purge-kernels --dry-run
test_combo "hexa-desktop-complete" --browser-cache-report --browser-cache-purge --check-zombies --journal-days=3 --upgrade --color=always --dry-run
test_combo "hexa-server-complete" --no-desktop-guard --fstrim --drop-caches --journal-days=14 --purge-kernels --orphan-purge --dry-run
test_combo "hexa-reboot-complete" --auto-reboot --auto-reboot-delay=30 --upgrade --purge-kernels --journal-days=7 --security-audit --dry-run
test_combo "hexa-display-complete" --color=always --progress=dots --upgrade --security-audit --check-zombies --browser-cache-report --dry-run
test_combo "septa-kitchen-sink" --upgrade --purge-kernels --orphan-purge --fstrim --drop-caches --clear-tmp-force --journal-days=7 --dry-run

# Cross-Category Combinations (8 tests)
echo ""
echo "=== Cross-Category Combinations ==="
test_combo "cross-maintenance-security" --upgrade --purge-kernels --security-audit --check-zombies --dry-run
test_combo "cross-fs-browser" --fstrim --orphan-purge --browser-cache-purge --dry-run
test_combo "cross-journal-display" --journal-days=14 --color=never --progress=quiet --dry-run
test_combo "cross-kernel-reboot-display" --purge-kernels --auto-reboot --color=always --progress=spinner --dry-run
test_combo "cross-snap-browser-desktop" --no-snap-clean-old --browser-cache-report --no-desktop-guard --dry-run
test_combo "cross-tmp-journal-kernel" --clear-tmp-force --journal-days=7 --purge-kernels --dry-run
test_combo "cross-security-fs-display" --security-audit --fstrim --color=always --dry-run
test_combo "cross-all-categories" --upgrade --security-audit --fstrim --browser-cache-report --journal-days=7 --color=never --dry-run

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ADVANCED FEATURE COMBINATION RESULTS                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo "Passed: $PASSED  Failed: $FAILED"
echo "Total: $((PASSED + FAILED))"

[ $FAILED -eq 0 ] && exit 0 || exit 1
