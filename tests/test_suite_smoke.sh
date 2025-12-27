#!/usr/bin/env bash
# Consolidated Smoke Test Suite - Basic + Extended + Ultra (60 tests)
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
    # Accept exit codes: 0 (success), 1 (GUI), 2 (edge case), 30 (failed services), or 100 (reboot required)
    # Exit 30 is common in CI environments where some systemd services may be in failed state
    if [[ $exit_code -eq 0 || $exit_code -eq 1 || $exit_code -eq 2 || $exit_code -eq 30 || $exit_code -eq 100 ]]; then
        echo "✅ PASS"
        # Verify JSON summary
        local json_file=$(ls -t /tmp/system-maintenance/sysmaint_*.json 2>/dev/null | head -1)
        if [ -f "$json_file" ] && grep -q '"script_version"' "$json_file"; then
            PASSED=$((PASSED + 1))
        else
            echo "[WARN] JSON summary missing"
            FAILED=$((FAILED + 1))
        fi
    else
        echo "❌ FAIL (exit: $exit_code)"
        FAILED=$((FAILED + 1))
    fi
}

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  CONSOLIDATED SMOKE TEST SUITE (60 Tests)                 ║"
echo "║  Basic (6) + Extended (24) + Ultra (30)                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ==================== BASIC SMOKE TESTS (6) ====================
echo "=== Basic Smoke Tests (6) ==="
run_test "basic-default"
run_test "basic-upgrade" --upgrade
run_test "basic-color" --color=always
run_test "basic-zombies" --check-zombies
run_test "basic-security" --security-audit
run_test "basic-browser" --browser-cache-report

# ==================== EXTENDED SMOKE TESTS (24) ====================
echo ""
echo "=== Filesystem Operations (3) ==="
run_test "ext-fstrim" --fstrim
run_test "ext-drop-caches" --drop-caches
run_test "ext-orphan-purge" --orphan-purge

echo ""
echo "=== Kernel Management (3) ==="
run_test "ext-kernel-keep2" --purge-kernels --keep-kernels=2
run_test "ext-kernel-keep4" --purge-kernels --keep-kernels=4
run_test "ext-kernel-upgrade" --purge-kernels --upgrade

echo ""
echo "=== Journal Configurations (3) ==="
run_test "ext-journal-3d" --journal-days=3
run_test "ext-journal-7d" --journal-days=7
run_test "ext-journal-30d" --journal-days=30

echo ""
echo "=== Browser Cache (3) ==="
run_test "ext-browser-report" --browser-cache-report
run_test "ext-browser-purge" --browser-cache-purge
run_test "ext-browser-both" --browser-cache-report --browser-cache-purge

echo ""
echo "=== Snap Management (3) ==="
run_test "ext-snap-no-old" --no-snap-clean-old
run_test "ext-snap-no-cache" --no-snap-clear-cache
run_test "ext-snap-both-off" --no-snap-clean-old --no-snap-clear-cache

echo ""
echo "=== TMP Cleanup (3) ==="
run_test "ext-tmp-default"
run_test "ext-tmp-disabled" --no-clear-tmp
run_test "ext-tmp-force" --clear-tmp-force

echo ""
echo "=== Desktop Guard (3) ==="
run_test "ext-desktop-on"
run_test "ext-desktop-off" --no-desktop-guard
run_test "ext-desktop-browser" --no-desktop-guard --browser-cache-purge

echo ""
echo "=== Auto-Reboot (3) ==="
run_test "ext-reboot-default" --auto-reboot
run_test "ext-reboot-15s" --auto-reboot --auto-reboot-delay=15
run_test "ext-reboot-60s" --auto-reboot --auto-reboot-delay=60

# ==================== ULTRA SMOKE TESTS (30) ====================
echo ""
echo "=== Advanced Filesystem (5) ==="
run_test "ultra-fs-all" --fstrim --drop-caches --orphan-purge
run_test "ultra-fs-trim" --fstrim --no-clear-tmp
run_test "ultra-fs-drop" --drop-caches --no-snap-clean-old
run_test "ultra-fs-orphan" --orphan-purge --no-snap-clear-cache
run_test "ultra-fs-none" --no-clear-tmp --no-snap-clean-old --no-snap-clear-cache

echo ""
echo "=== Advanced Kernel (5) ==="
run_test "ultra-kernel-keep1" --purge-kernels --keep-kernels=1 --upgrade
run_test "ultra-kernel-keep5" --purge-kernels --keep-kernels=5
run_test "ultra-kernel-keep3-reboot" --purge-kernels --keep-kernels=3 --auto-reboot
run_test "ultra-kernel-no-purge" --upgrade
run_test "ultra-kernel-security" --purge-kernels --security-audit

echo ""
echo "=== Advanced Journal (5) ==="
run_test "ultra-journal-1d" --journal-days=1
run_test "ultra-journal-14d" --journal-days=14
run_test "ultra-journal-21d" --journal-days=21
run_test "ultra-journal-60d" --journal-days=60
run_test "ultra-journal-90d" --journal-days=90

echo ""
echo "=== Advanced Browser (5) ==="
run_test "ultra-browser-desktop-report" --browser-cache-report --no-desktop-guard
run_test "ultra-browser-desktop-purge" --browser-cache-purge --no-desktop-guard
run_test "ultra-browser-guard-report" --browser-cache-report
run_test "ultra-browser-guard-purge" --browser-cache-purge
run_test "ultra-browser-all-no-guard" --browser-cache-report --browser-cache-purge --no-desktop-guard

echo ""
echo "=== Advanced Security (5) ==="
run_test "ultra-security-full" --security-audit --check-zombies --upgrade --purge-kernels
run_test "ultra-security-audit" --security-audit --no-clear-tmp
run_test "ultra-security-zombies" --check-zombies --no-snap-clean-old
run_test "ultra-security-upgrade" --upgrade --security-audit
run_test "ultra-security-no-upgrade" --security-audit --check-zombies

echo ""
echo "=== Advanced Display (5) ==="
run_test "ultra-display-spinner" --color=always --progress=spinner
run_test "ultra-display-dots" --color=never --progress=dots
run_test "ultra-display-quiet" --color=auto --progress=quiet
run_test "ultra-display-always-quiet" --color=always --progress=quiet
run_test "ultra-display-never-spinner" --color=never --progress=spinner

# === Profiles Subcommand Tests (Tier 1) ===
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  PROFILES SUBCOMMAND TESTS                                 ║"
echo "╚════════════════════════════════════════════════════════════╝"

profiles_test() {
  local label="$1" output="$2" needle="$3"
  echo -n "Test: $label... "
  if [[ "$output" == *"$needle"* ]]; then
    echo "✅ PASS"
    PASSED=$((PASSED + 1))
  else
    echo "❌ FAIL (expected '$needle')"
    FAILED=$((FAILED + 1))
  fi
}

minimal_cmd=$(bash "$SCRIPT" profiles --profile minimal --print-command 2>/dev/null || echo "")
profiles_test "minimal includes --dry-run" "$minimal_cmd" "--dry-run"
profiles_test "minimal includes --json-summary" "$minimal_cmd" "--json-summary"

server_cmd=$(bash "$SCRIPT" profiles --profile server --print-command 2>/dev/null || echo "")
profiles_test "server includes --security-audit" "$server_cmd" "--security-audit"
profiles_test "server includes --check-zombies" "$server_cmd" "--check-zombies"

extra_cmd=$(bash "$SCRIPT" profiles --profile desktop --print-command -- --color=never 2>/dev/null || echo "")
profiles_test "extra flags appended" "$extra_cmd" "--color=never"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  CONSOLIDATED SMOKE TEST RESULTS                           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo "Passed: $PASSED  Failed: $FAILED"
echo "Total: $((PASSED + FAILED))"

[ $FAILED -eq 0 ] && exit 0 || exit 1
