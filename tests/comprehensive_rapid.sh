#!/usr/bin/env bash
# Comprehensive Rapid Test Suite - Quick validation of extended scenarios
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery

set -euo pipefail

SCRIPT="./sysmaint"
declare -A RESULTS

rapid_test() {
    local name="$1"
    shift
    bash "$SCRIPT" "$@" >/dev/null 2>&1 && RESULTS["$name"]="✅" || RESULTS["$name"]="❌"
}

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  COMPREHENSIVE RAPID TEST SUITE                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Running comprehensive test scenarios (this may take a few minutes)..."
echo ""

# Category 1: Extended Smoke Tests (24 tests)
rapid_test "smoke-fstrim" --fstrim --dry-run
rapid_test "smoke-drop-caches" --drop-caches --dry-run
rapid_test "smoke-orphan" --orphan-purge --dry-run
rapid_test "smoke-kernel2" --purge-kernels --keep-kernels=2 --dry-run
rapid_test "smoke-kernel4" --purge-kernels --keep-kernels=4 --dry-run
rapid_test "smoke-kernel-upgrade" --purge-kernels --upgrade --dry-run
rapid_test "smoke-journal3" --journal-days=3 --dry-run
rapid_test "smoke-journal7" --journal-days=7 --dry-run
rapid_test "smoke-journal30" --journal-days=30 --dry-run
rapid_test "smoke-browser-report" --browser-cache-report --dry-run
rapid_test "smoke-browser-purge" --browser-cache-purge --dry-run
rapid_test "smoke-browser-both" --browser-cache-report --browser-cache-purge --dry-run
rapid_test "smoke-snap-noold" --no-snap-clean-old --dry-run
rapid_test "smoke-snap-nocache" --no-snap-clear-cache --dry-run
rapid_test "smoke-snap-both" --no-snap-clean-old --no-snap-clear-cache --dry-run
rapid_test "smoke-tmp-disabled" --no-clear-tmp --dry-run
rapid_test "smoke-tmp-force" --clear-tmp-force --dry-run
rapid_test "smoke-desktop-off" --no-desktop-guard --dry-run
rapid_test "smoke-reboot15" --auto-reboot --auto-reboot-delay=15 --dry-run
rapid_test "smoke-reboot60" --auto-reboot --auto-reboot-delay=60 --dry-run
rapid_test "smoke-color-never" --color=never --dry-run
rapid_test "smoke-progress-dots" --progress=dots --dry-run
rapid_test "smoke-progress-quiet" --progress=quiet --dry-run
rapid_test "smoke-all-security" --security-audit --check-zombies --dry-run

# Category 2: Extended Edge Cases (26 tests)
rapid_test "edge-journal-min" --journal-days=1 --dry-run
rapid_test "edge-journal-max" --journal-days=365 --dry-run
rapid_test "edge-kernel-min" --purge-kernels --keep-kernels=1 --dry-run
rapid_test "edge-kernel-max" --purge-kernels --keep-kernels=10 --dry-run
rapid_test "edge-reboot-min" --auto-reboot --auto-reboot-delay=0 --dry-run
rapid_test "edge-reboot-max" --auto-reboot --auto-reboot-delay=300 --dry-run
rapid_test "edge-double-upgrade" --upgrade --upgrade --dry-run
rapid_test "edge-conflict-tmp" --clear-tmp-force --no-clear-tmp --dry-run
rapid_test "edge-order1" --dry-run --upgrade --security-audit
rapid_test "edge-order2" --security-audit --upgrade --dry-run
rapid_test "edge-order3" --upgrade --dry-run --security-audit
rapid_test "edge-order4" --color=never --progress=quiet --dry-run
rapid_test "edge-order5" --progress=quiet --color=never --dry-run
rapid_test "edge-help" --help
rapid_test "edge-version" --version
rapid_test "edge-triple-dryrun" --dry-run --dry-run --dry-run
rapid_test "edge-max-flags" --upgrade --purge-kernels --security-audit --check-zombies --browser-cache-report --orphan-purge --fstrim --drop-caches --dry-run
rapid_test "edge-minimal-flags" --no-clear-tmp --no-snap-clean-old --no-desktop-guard --dry-run
rapid_test "edge-color-auto" --color=auto --dry-run
rapid_test "edge-spinner" --progress=spinner --dry-run
rapid_test "edge-journal14" --journal-days=14 --dry-run
rapid_test "edge-journal21" --journal-days=21 --dry-run
rapid_test "edge-kernel5" --purge-kernels --keep-kernels=5 --dry-run
rapid_test "edge-reboot45" --auto-reboot --auto-reboot-delay=45 --dry-run
rapid_test "edge-reboot90" --auto-reboot --auto-reboot-delay=90 --dry-run
rapid_test "edge-all-disabled" --no-clear-tmp --no-snap-clean-old --no-snap-clear-cache --no-desktop-guard --dry-run

# Category 3: Extended Full-Cycle Scenarios (20 tests)
rapid_test "fullcycle-server-basic" --no-desktop-guard --journal-days=14 --dry-run
rapid_test "fullcycle-server-full" --no-desktop-guard --journal-days=14 --fstrim --drop-caches --orphan-purge --dry-run
rapid_test "fullcycle-desktop-basic" --browser-cache-report --journal-days=3 --dry-run
rapid_test "fullcycle-desktop-full" --browser-cache-report --browser-cache-purge --check-zombies --journal-days=3 --dry-run
rapid_test "fullcycle-maintenance" --upgrade --purge-kernels --orphan-purge --dry-run
rapid_test "fullcycle-security" --security-audit --check-zombies --upgrade --dry-run
rapid_test "fullcycle-minimal" --no-clear-tmp --no-snap-clean-old --dry-run
rapid_test "fullcycle-aggressive" --upgrade --purge-kernels --clear-tmp-force --browser-cache-purge --orphan-purge --fstrim --drop-caches --dry-run
rapid_test "fullcycle-quiet" --progress=quiet --color=never --dry-run
rapid_test "fullcycle-verbose" --progress=spinner --color=always --dry-run
rapid_test "fullcycle-journal-short" --journal-days=1 --dry-run
rapid_test "fullcycle-journal-long" --journal-days=60 --dry-run
rapid_test "fullcycle-kernel-conservative" --purge-kernels --keep-kernels=4 --dry-run
rapid_test "fullcycle-kernel-aggressive" --purge-kernels --keep-kernels=1 --dry-run
rapid_test "fullcycle-browser-only" --browser-cache-report --browser-cache-purge --no-clear-tmp --no-snap-clean-old --dry-run
rapid_test "fullcycle-snap-disabled" --no-snap-clean-old --no-snap-clear-cache --dry-run
rapid_test "fullcycle-filesystem" --fstrim --drop-caches --dry-run
rapid_test "fullcycle-reboot-quick" --auto-reboot --auto-reboot-delay=10 --upgrade --dry-run
rapid_test "fullcycle-reboot-slow" --auto-reboot --auto-reboot-delay=120 --upgrade --dry-run
rapid_test "fullcycle-everything" --upgrade --purge-kernels --keep-kernels=3 --security-audit --check-zombies --browser-cache-report --browser-cache-purge --orphan-purge --fstrim --drop-caches --journal-days=7 --color=always --progress=dots --dry-run

# Category 4: Extended Feature Combinations (30 tests)
rapid_test "combo-color-progress1" --color=always --progress=spinner --dry-run
rapid_test "combo-color-progress2" --color=never --progress=dots --dry-run
rapid_test "combo-color-progress3" --color=auto --progress=quiet --dry-run
rapid_test "combo-journal-kernel1" --journal-days=7 --purge-kernels --keep-kernels=2 --dry-run
rapid_test "combo-journal-kernel2" --journal-days=14 --purge-kernels --keep-kernels=3 --dry-run
rapid_test "combo-journal-kernel3" --journal-days=30 --purge-kernels --keep-kernels=4 --dry-run
rapid_test "combo-browser-security1" --browser-cache-report --security-audit --dry-run
rapid_test "combo-browser-security2" --browser-cache-purge --check-zombies --dry-run
rapid_test "combo-browser-security3" --browser-cache-report --browser-cache-purge --security-audit --check-zombies --dry-run
rapid_test "combo-snap-tmp1" --no-snap-clean-old --no-clear-tmp --dry-run
rapid_test "combo-snap-tmp2" --no-snap-clear-cache --clear-tmp-force --dry-run
rapid_test "combo-snap-tmp3" --no-snap-clean-old --no-snap-clear-cache --no-clear-tmp --dry-run
rapid_test "combo-desktop-browser1" --no-desktop-guard --browser-cache-purge --dry-run
rapid_test "combo-desktop-browser2" --browser-cache-report --journal-days=3 --dry-run
rapid_test "combo-upgrade-kernel1" --upgrade --purge-kernels --dry-run
rapid_test "combo-upgrade-kernel2" --upgrade --purge-kernels --keep-kernels=2 --dry-run
rapid_test "combo-upgrade-kernel3" --upgrade --purge-kernels --keep-kernels=4 --dry-run
rapid_test "combo-upgrade-security" --upgrade --security-audit --check-zombies --dry-run
rapid_test "combo-orphan-filesystem" --orphan-purge --fstrim --drop-caches --dry-run
rapid_test "combo-orphan-kernel" --orphan-purge --purge-kernels --dry-run
rapid_test "combo-reboot-upgrade1" --auto-reboot --upgrade --dry-run
rapid_test "combo-reboot-upgrade2" --auto-reboot --auto-reboot-delay=30 --upgrade --purge-kernels --dry-run
rapid_test "combo-all-fs-ops" --fstrim --drop-caches --orphan-purge --clear-tmp-force --dry-run
rapid_test "combo-all-browser-ops" --browser-cache-report --browser-cache-purge --no-desktop-guard --dry-run
rapid_test "combo-all-kernel-ops" --upgrade --purge-kernels --keep-kernels=3 --auto-reboot --dry-run
rapid_test "combo-all-security-ops" --security-audit --check-zombies --upgrade --dry-run
rapid_test "combo-all-journal-ops" --journal-days=7 --dry-run
rapid_test "combo-mixed1" --upgrade --browser-cache-report --journal-days=7 --color=always --dry-run
rapid_test "combo-mixed2" --purge-kernels --orphan-purge --fstrim --progress=dots --dry-run
rapid_test "combo-mixed3" --security-audit --browser-cache-purge --no-snap-clean-old --journal-days=14 --dry-run

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  COMPREHENSIVE TEST RESULTS SUMMARY                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Count results
PASS_COUNT=0
FAIL_COUNT=0
for result in "${RESULTS[@]}"; do
    if [ "$result" = "✅" ]; then
        ((PASS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi
done

echo "Total Tests: ${#RESULTS[@]}"
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"
echo ""

# Display by category
echo "=== Extended Smoke Tests (24 tests) ==="
for key in "${!RESULTS[@]}"; do
    if [[ $key == smoke-* ]]; then
        echo "  ${RESULTS[$key]} $key"
    fi
done | sort

echo ""
echo "=== Extended Edge Cases (26 tests) ==="
for key in "${!RESULTS[@]}"; do
    if [[ $key == edge-* ]]; then
        echo "  ${RESULTS[$key]} $key"
    fi
done | sort

echo ""
echo "=== Extended Full-Cycle (20 tests) ==="
for key in "${!RESULTS[@]}"; do
    if [[ $key == fullcycle-* ]]; then
        echo "  ${RESULTS[$key]} $key"
    fi
done | sort

echo ""
echo "=== Extended Feature Combinations (30 tests) ==="
for key in "${!RESULTS[@]}"; do
    if [[ $key == combo-* ]]; then
        echo "  ${RESULTS[$key]} $key"
    fi
done | sort

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
if [ $FAIL_COUNT -eq 0 ]; then
    echo "║  ✅ ALL COMPREHENSIVE TESTS PASSED (100/100)               ║"
else
    echo "║  ⚠️  SOME TESTS FAILED                                      ║"
fi
echo "╚════════════════════════════════════════════════════════════╝"

[ $FAIL_COUNT -eq 0 ] && exit 0 || exit 1
