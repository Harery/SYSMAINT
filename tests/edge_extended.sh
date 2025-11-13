#!/usr/bin/env bash
# Extended Edge Case Tests - Boundary conditions and special scenarios
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery

set -euo pipefail

SCRIPT="./sysmaint"
PASSED=0
FAILED=0

test_case() {
    local name="$1"
    shift
    local args="$*"
    
    echo -n "[TEST] $name: "
    if bash "$SCRIPT" $args >/dev/null 2>&1; then
        echo "✅ PASS"
        ((PASSED++))
    else
        local code=$?
        if [ "$name" = "expected-fail" ] || [[ "$name" == *"invalid"* ]]; then
            echo "✅ PASS (expected failure, code: $code)"
            ((PASSED++))
        else
            echo "❌ FAIL (code: $code)"
            ((FAILED++))
        fi
    fi
}

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  EXTENDED EDGE CASE TESTS                                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Boundary value tests
echo "=== Boundary Values ==="
test_case "journal-min" --journal-days=1 --dry-run
test_case "journal-max" --journal-days=365 --dry-run
test_case "kernel-keep-min" --purge-kernels --keep-kernels=1 --dry-run
test_case "kernel-keep-max" --purge-kernels --keep-kernels=10 --dry-run
test_case "reboot-delay-min" --auto-reboot --auto-reboot-delay=0 --dry-run
test_case "reboot-delay-max" --auto-reboot --auto-reboot-delay=300 --dry-run

# Multiple flag combinations
echo ""
echo "=== Multiple Flag Combinations ==="
test_case "all-colors" --color=always --dry-run
test_case "all-progress" --progress=spinner --dry-run
test_case "double-upgrade" --upgrade --upgrade --dry-run
test_case "conflicting-tmp" --clear-tmp-force --no-clear-tmp --dry-run
test_case "conflicting-snap1" --no-snap-clean-old --no-snap-clean-old --dry-run
test_case "conflicting-snap2" --no-snap-clear-cache --no-snap-clear-cache --dry-run

# Flag order variations
echo ""
echo "=== Flag Order Variations ==="
test_case "order1" --dry-run --upgrade --security-audit
test_case "order2" --security-audit --upgrade --dry-run
test_case "order3" --upgrade --dry-run --security-audit
test_case "order4" --color=never --progress=quiet --dry-run
test_case "order5" --progress=quiet --color=never --dry-run

# Empty and whitespace scenarios
echo ""
echo "=== Special Scenarios ==="
test_case "help-flag" --help
test_case "version-flag" --version
test_case "dry-run-only" --dry-run
test_case "multiple-dry-run" --dry-run --dry-run --dry-run

# Combined stress test
echo ""
echo "=== Combined Stress Tests ==="
test_case "max-flags" --upgrade --purge-kernels --keep-kernels=3 --security-audit --check-zombies --browser-cache-report --browser-cache-purge --orphan-purge --fstrim --drop-caches --journal-days=7 --auto-reboot --auto-reboot-delay=30 --color=always --progress=dots --dry-run

test_case "minimal-flags" --no-clear-tmp --no-snap-clean-old --no-snap-clear-cache --no-desktop-guard --dry-run

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  EXTENDED EDGE CASE RESULTS                                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo "Passed: $PASSED  Failed: $FAILED"

[ $FAILED -eq 0 ] && exit 0 || exit 1
