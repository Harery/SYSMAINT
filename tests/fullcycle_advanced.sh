#!/usr/bin/env bash
# Advanced Full-Cycle Tests - Complex real-world scenarios
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery

set -euo pipefail

SCRIPT="./sysmaint"
PASSED=0
FAILED=0

test_fullcycle() {
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
echo "║  ADVANCED FULL-CYCLE SCENARIOS (25 Tests)                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Production Server Scenarios (5 tests)
echo "=== Production Server Scenarios ==="
test_fullcycle "prod-server-minimal" --no-desktop-guard --journal-days=30 --dry-run
test_fullcycle "prod-server-standard" --no-desktop-guard --journal-days=14 --fstrim --dry-run
test_fullcycle "prod-server-full" --no-desktop-guard --journal-days=7 --fstrim --drop-caches --orphan-purge --purge-kernels --keep-kernels=2 --dry-run
test_fullcycle "prod-server-upgrade" --no-desktop-guard --upgrade --purge-kernels --auto-reboot --journal-days=14 --dry-run
test_fullcycle "prod-server-security" --no-desktop-guard --security-audit --check-zombies --journal-days=14 --dry-run

# Production Desktop Scenarios (5 tests)
echo ""
echo "=== Production Desktop Scenarios ==="
test_fullcycle "prod-desktop-daily" --browser-cache-report --journal-days=1 --dry-run
test_fullcycle "prod-desktop-weekly" --browser-cache-report --browser-cache-purge --journal-days=7 --dry-run
test_fullcycle "prod-desktop-full" --browser-cache-purge --check-zombies --journal-days=3 --clear-tmp-force --dry-run
test_fullcycle "prod-desktop-upgrade" --upgrade --browser-cache-report --journal-days=3 --auto-reboot --auto-reboot-delay=60 --dry-run
test_fullcycle "prod-desktop-security" --security-audit --check-zombies --browser-cache-report --journal-days=3 --dry-run

# Maintenance Window Scenarios (5 tests)
echo ""
echo "=== Maintenance Window Scenarios ==="
test_fullcycle "maint-quick" --upgrade --journal-days=7 --dry-run
test_fullcycle "maint-medium" --upgrade --purge-kernels --orphan-purge --journal-days=7 --dry-run
test_fullcycle "maint-full" --upgrade --purge-kernels --keep-kernels=2 --orphan-purge --fstrim --drop-caches --clear-tmp-force --journal-days=7 --dry-run
test_fullcycle "maint-with-reboot" --upgrade --purge-kernels --auto-reboot --auto-reboot-delay=30 --journal-days=7 --dry-run
test_fullcycle "maint-security-focus" --upgrade --security-audit --check-zombies --purge-kernels --journal-days=7 --dry-run

# Specialized Workload Scenarios (5 tests)
echo ""
echo "=== Specialized Workload Scenarios ==="
test_fullcycle "workload-database" --no-desktop-guard --journal-days=30 --no-clear-tmp --drop-caches --dry-run
test_fullcycle "workload-webserver" --no-desktop-guard --journal-days=14 --fstrim --orphan-purge --dry-run
test_fullcycle "workload-developer" --browser-cache-report --journal-days=3 --no-snap-clean-old --dry-run
test_fullcycle "workload-kiosk" --browser-cache-purge --clear-tmp-force --journal-days=1 --no-snap-clean-old --no-snap-clear-cache --dry-run
test_fullcycle "workload-render" --no-desktop-guard --drop-caches --journal-days=7 --no-clear-tmp --dry-run

# CI/CD and Automation Scenarios (5 tests)
echo ""
echo "=== CI/CD and Automation Scenarios ==="
test_fullcycle "cicd-quiet" --progress=quiet --color=never --upgrade --dry-run
test_fullcycle "cicd-verbose" --progress=dots --color=always --upgrade --security-audit --dry-run
test_fullcycle "cicd-full-silent" --progress=quiet --color=never --upgrade --purge-kernels --orphan-purge --dry-run
test_fullcycle "cicd-monitoring" --progress=spinner --color=auto --security-audit --check-zombies --dry-run
test_fullcycle "cicd-scheduled" --progress=quiet --upgrade --journal-days=14 --purge-kernels --keep-kernels=3 --dry-run

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ADVANCED FULL-CYCLE RESULTS                               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo "Passed: $PASSED  Failed: $FAILED"
echo "Total: $((PASSED + FAILED))"

[ $FAILED -eq 0 ] && exit 0 || exit 1
