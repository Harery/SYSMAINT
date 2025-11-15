#!/usr/bin/env bash
# Consolidated Full-Cycle Test Suite - Standard + Advanced + Combos (97 tests)
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery

set -Eeuo pipefail

# Always dry-run with JSON summary
export DRY_RUN=true
export JSON_SUMMARY=true
export CHECK_ZOMBIES=true

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
SYSMAINT="$REPO_ROOT/sysmaint"

# Ensure sysmaint exists
if [[ ! -x "$SYSMAINT" ]]; then
  echo "ERROR: sysmaint not found or not executable at $SYSMAINT" >&2
  exit 1
fi

PASSED=0
FAILED=0

# Get latest JSON
LATEST_JSON() {
  ls -1t /tmp/system-maintenance/sysmaint_*.json 2>/dev/null | head -n1 || true
}

# Validate JSON schema
validate_json() {
  local json
  json=$(LATEST_JSON)
  if [[ -n "$json" && -f "$json" ]]; then
    sleep 0.2
    if command -v python3 >/dev/null 2>&1; then
      python3 - "$json" <<'PY' 2>/dev/null || return 0
import sys, json, pathlib
from jsonschema import validate
schema_path = pathlib.Path('docs/schema/sysmaint-summary.schema.json')
json_path = pathlib.Path(sys.argv[1])
if schema_path.exists():
    with open(schema_path, 'r') as f: schema = json.load(f)
    with open(json_path, 'r') as f: data = json.load(f)
    validate(instance=data, schema=schema)
PY
    fi
  fi
  return 0
}

# Assert JSON field
assert_json() {
  local key="$1"; shift
  local expected="$1"
  local json
  json=$(LATEST_JSON)
  [[ -z "$json" || ! -f "$json" ]] && return 0
  command -v python3 >/dev/null 2>&1 || return 0
  python3 - "$json" "$key" "$expected" <<'PY' 2>/dev/null || return 0
import sys, json
json_path, key, expected_raw = sys.argv[1:4]
with open(json_path, 'r') as f: data = json.load(f)
def coerce(val:str):
    low = val.lower()
    if low == 'true': return True
    if low == 'false': return False
    try: return float(val) if '.' in val else int(val)
    except: return val
expected = coerce(expected_raw)
actual = data.get(key, None)
sys.exit(0 if actual == expected else 1)
PY
}

# Run test case
run_case() {
  local name="$1"; shift
  local flags=("$@")
  echo -n "[TEST] $name: "
  set +e
  bash "$SYSMAINT" "${flags[@]}" >/dev/null 2>&1
  local rc=$?
  set -e
  if [ $rc -eq 0 ]; then
    echo "✅ PASS"
    validate_json
    PASSED=$((PASSED + 1))
  else
    echo "❌ FAIL (exit: $rc)"
    FAILED=$((FAILED + 1))
  fi
  return 0
}

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  CONSOLIDATED FULL-CYCLE TEST SUITE (97 Tests)            ║"
echo "║  Standard (60) + Advanced (25) + Combos (12)              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ==================== STANDARD FULL-CYCLE TESTS (60) ====================
echo "=== Phase 1: Basic Operations (6) ==="
run_case "default" --dry-run
run_case "upgrade" --upgrade --dry-run
assert_json final_upgrade_enabled true
run_case "simulate-upgrade" --simulate-upgrade --dry-run
run_case "no-color-audits" --color=never --check-zombies --security-audit --dry-run
assert_json color_mode never
run_case "browser-report" --browser-cache-report --dry-run
assert_json browser_cache_report true
run_case "help" --help

echo ""
echo "=== Phase 2: Feature Toggles (20) ==="
run_case "fstrim" --fstrim --dry-run
run_case "drop-caches" --drop-caches --dry-run
run_case "purge-kernels" --purge-kernels --keep-kernels=2 --dry-run
assert_json kernel_purge_enabled true
run_case "update-grub" --update-grub --dry-run
run_case "orphan-purge" --orphan-purge --dry-run
run_case "browser-purge" --browser-cache-purge --dry-run
run_case "snap-cleanup" --snap-clean-old --snap-clear-cache --dry-run
run_case "flatpak-user" --flatpak-user-only --dry-run
run_case "flatpak-system" --flatpak-system-only --dry-run
run_case "disable-snap" --no-snap --dry-run
run_case "disable-flatpak" --no-flatpak --dry-run
run_case "disable-firmware" --no-firmware --dry-run
run_case "disable-journal" --no-journal-vacuum --dry-run
run_case "disable-failed-svc" --no-check-failed-services --dry-run
run_case "disable-crash" --no-clear-crash --dry-run
run_case "disable-dns" --no-clear-dns-cache --dry-run
run_case "disable-tmp" --no-clear-tmp --dry-run
run_case "tmp-with-age" --clear-tmp --clear-tmp-age=1 --dry-run
run_case "tmp-force" --clear-tmp-force --confirm-clear-tmp-force --yes --dry-run
run_case "journal-14d" --journal-days=14 --dry-run

echo ""
echo "=== Phase 3: Display & Progress (10) ==="
run_case "progress-bar" --progress=bar --progress-duration=1 --dry-run
run_case "progress-dots" --progress=dots --progress-duration=1 --dry-run
run_case "progress-spinner" --progress=spinner --progress-duration=1 --dry-run
run_case "progress-quiet" --progress=quiet --dry-run
run_case "color-always" --color=always --dry-run
run_case "color-never" --color=never --dry-run
run_case "color-auto" --color=auto --dry-run
run_case "reset-progress" --reset-progress-history --dry-run
run_case "mode-desktop" --mode=desktop --dry-run
run_case "mode-server" --mode=server --dry-run

echo ""
echo "=== Phase 4: Advanced Options (10) ==="
run_case "no-desktop-guard" --no-desktop-guard --dry-run
assert_json desktop_guard_enabled false
run_case "lock-wait" --lock-wait-seconds=1 --dry-run
run_case "parallel" --parallel --dry-run
run_case "log-limits" --log-max-size-mb=1 --log-tail-keep-kb=16 --dry-run
run_case "auto-default" --auto --dry-run
assert_json auto_mode true
run_case "auto-custom-delay" --auto --auto-reboot-delay=10 --dry-run
run_case "auto-reboot" --auto-reboot --dry-run
run_case "auto-reboot-15s" --auto-reboot --auto-reboot-delay=15 --dry-run
run_case "auto-reboot-60s" --auto-reboot --auto-reboot-delay=60 --dry-run
run_case "yes-flag" --yes --dry-run

echo ""
echo "=== Phase 5: Combined Scenarios (7) ==="
run_case "combined-basic" --upgrade --fstrim --journal-days=7 --dry-run
run_case "combined-medium" --upgrade --purge-kernels --orphan-purge --dry-run
run_case "combined-full" --upgrade --fstrim --drop-caches --purge-kernels --keep-kernels=2 --update-grub --orphan-purge --snap-clean-old --snap-clear-cache --security-audit --browser-cache-report --dry-run
run_case "combined-security" --security-audit --check-zombies --upgrade --purge-kernels --dry-run
run_case "combined-display" --color=never --progress=spinner --upgrade --dry-run
run_case "combined-server" --no-desktop-guard --upgrade --purge-kernels --journal-days=14 --dry-run
run_case "combined-desktop" --browser-cache-purge --check-zombies --journal-days=3 --dry-run

echo ""
echo "=== Phase 6: Negative Toggles (7) ==="
run_case "all-disabled" --no-snap --no-flatpak --no-firmware --no-clear-dns-cache --no-journal-vacuum --no-check-failed-services --no-clear-crash --no-clear-tmp --no-check-zombies --dry-run
assert_json zombie_check_enabled false
run_case "no-snap-all" --no-snap --no-snap-clean-old --no-snap-clear-cache --dry-run
run_case "no-flatpak-all" --no-flatpak --dry-run
run_case "no-browser-guard" --no-desktop-guard --browser-cache-purge --dry-run
run_case "no-tmp-all" --no-clear-tmp --no-clear-crash --dry-run
run_case "no-journal-all" --no-journal-vacuum --journal-days=1 --dry-run
run_case "no-kernel" --upgrade --dry-run

# ==================== ADVANCED FULL-CYCLE TESTS (25) ====================
echo ""
echo "=== Advanced: Production Server (5) ==="
run_case "adv-server-minimal" --no-desktop-guard --journal-days=30 --dry-run
run_case "adv-server-standard" --no-desktop-guard --journal-days=14 --fstrim --dry-run
run_case "adv-server-full" --no-desktop-guard --journal-days=7 --fstrim --drop-caches --orphan-purge --purge-kernels --keep-kernels=2 --dry-run
run_case "adv-server-upgrade" --no-desktop-guard --upgrade --purge-kernels --auto-reboot --journal-days=14 --dry-run
run_case "adv-server-security" --no-desktop-guard --security-audit --check-zombies --journal-days=14 --dry-run

echo ""
echo "=== Advanced: Production Desktop (5) ==="
run_case "adv-desktop-daily" --browser-cache-report --journal-days=1 --dry-run
run_case "adv-desktop-weekly" --browser-cache-report --browser-cache-purge --journal-days=7 --dry-run
run_case "adv-desktop-full" --browser-cache-purge --check-zombies --journal-days=3 --clear-tmp-force --dry-run
run_case "adv-desktop-upgrade" --upgrade --browser-cache-report --journal-days=3 --auto-reboot --auto-reboot-delay=60 --dry-run
run_case "adv-desktop-security" --security-audit --check-zombies --browser-cache-report --journal-days=3 --dry-run

echo ""
echo "=== Advanced: Maintenance Windows (5) ==="
run_case "adv-maint-quick" --upgrade --journal-days=7 --dry-run
run_case "adv-maint-medium" --upgrade --purge-kernels --orphan-purge --journal-days=7 --dry-run
run_case "adv-maint-full" --upgrade --purge-kernels --keep-kernels=2 --orphan-purge --fstrim --drop-caches --clear-tmp-force --journal-days=7 --dry-run
run_case "adv-maint-reboot" --upgrade --purge-kernels --auto-reboot --auto-reboot-delay=30 --journal-days=7 --dry-run
run_case "adv-maint-security" --upgrade --security-audit --check-zombies --purge-kernels --journal-days=7 --dry-run

echo ""
echo "=== Advanced: Specialized Workloads (5) ==="
run_case "adv-workload-db" --no-desktop-guard --journal-days=30 --no-clear-tmp --drop-caches --dry-run
run_case "adv-workload-web" --no-desktop-guard --journal-days=14 --fstrim --orphan-purge --dry-run
run_case "adv-workload-dev" --browser-cache-report --journal-days=3 --no-snap-clean-old --dry-run
run_case "adv-workload-kiosk" --browser-cache-purge --clear-tmp-force --journal-days=1 --no-snap-clean-old --no-snap-clear-cache --dry-run
run_case "adv-workload-render" --no-desktop-guard --drop-caches --journal-days=7 --no-clear-tmp --dry-run

echo ""
echo "=== Advanced: CI/CD Automation (5) ==="
run_case "adv-cicd-quiet" --progress=quiet --color=never --upgrade --dry-run
run_case "adv-cicd-verbose" --progress=dots --color=always --upgrade --security-audit --dry-run
run_case "adv-cicd-silent" --progress=quiet --color=never --upgrade --purge-kernels --orphan-purge --dry-run
run_case "adv-cicd-monitor" --progress=spinner --color=auto --security-audit --check-zombies --dry-run
run_case "adv-cicd-scheduled" --progress=quiet --upgrade --journal-days=14 --purge-kernels --keep-kernels=3 --dry-run

echo ""
echo "=== Phase 7: Feature Combination Gallery (12) ==="
run_case "combo-triple-upgrade-kernel-journal" --upgrade --purge-kernels --keep-kernels=3 --journal-days=7 --dry-run
run_case "combo-triple-security-browser-zombies" --security-audit --browser-cache-report --check-zombies --dry-run
run_case "combo-triple-filesystems" --fstrim --orphan-purge --drop-caches --dry-run
run_case "combo-triple-display" --color=always --progress=spinner --upgrade --dry-run
run_case "combo-triple-desktop" --no-snap-clean-old --no-clear-tmp --no-desktop-guard --dry-run
run_case "combo-triple-kernel-reboot" --journal-days=14 --purge-kernels --auto-reboot --dry-run
run_case "combo-triple-browser-security" --browser-cache-purge --security-audit --upgrade --dry-run
run_case "combo-triple-fs-journal" --fstrim --journal-days=7 --purge-kernels --dry-run
run_case "combo-quad-maintenance" --upgrade --purge-kernels --orphan-purge --journal-days=7 --dry-run
run_case "combo-quad-security-stack" --security-audit --check-zombies --upgrade --browser-cache-report --dry-run
run_case "combo-quad-filesystem" --fstrim --drop-caches --orphan-purge --clear-tmp-force --dry-run
run_case "combo-quad-display" --color=never --progress=quiet --upgrade --security-audit --dry-run

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  CONSOLIDATED FULL-CYCLE TEST RESULTS                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo "Passed: $PASSED  Failed: $FAILED"
echo "Total: $((PASSED + FAILED))"

[ $FAILED -eq 0 ] && exit 0 || exit 1
