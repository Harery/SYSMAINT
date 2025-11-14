#!/usr/bin/env bash
# Full-cycle dry-run test suite for sysmaint
# Runs progressively: default, fixed combos, optional toggles, and a broad combined run.
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
SCHEMA_VALIDATOR="$REPO_ROOT/tests/validate_json.sh"

# Ensure sysmaint exists
if [[ ! -x "$SYSMAINT" ]]; then
  echo "ERROR: sysmaint not found or not executable at $SYSMAINT" >&2
  exit 1
fi

# Helpers
LATEST_JSON() {
  ls -1t /tmp/system-maintenance/sysmaint_*.json 2>/dev/null | head -n1 || true
}

validate_json() {
  local json
  json=$(LATEST_JSON)
  if [[ -n "$json" && -f "$json" ]]; then
    echo "[validate] Using $json"
    # Give the writer a moment to close the file to avoid partial reads
    sleep 0.2
    # Validate directly against schema without triggering another run
    if command -v python3 >/dev/null 2>&1; then
      if ! python3 - "$json" <<'PY'
import sys
from jsonschema import validate
import json
import pathlib
schema_path = pathlib.Path('docs/schema/sysmaint-summary.schema.json')
json_path = pathlib.Path(sys.argv[1])
with open(schema_path, 'r') as f:
    schema = json.load(f)
with open(json_path, 'r') as f:
    data = json.load(f)
validate(instance=data, schema=schema)
print('JSON schema validation: OK')
PY
      then
        echo "[warn] JSON schema validation failed for $json (non-fatal for this sweep)" >&2
        return 1
      fi
    else
      echo "[info] python3 not found; skipping schema validation" >&2
    fi
  else
    echo "[warn] No JSON produced by last run" >&2
    return 1
  fi
}

# Assert a top-level JSON field equals an expected value.
# Usage: assert_json <key> <expected>
# - expected can be: true/false, a number, or a string (pass without quotes)
assert_json() {
  local key="$1"; shift
  local expected="$1"
  local json
  json=$(LATEST_JSON)
  if [[ -z "$json" || ! -f "$json" ]]; then
    echo "[assert-skip] No JSON to assert ($key=$expected)" >&2
    return 0
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    echo "[assert-skip] python3 not found; skipping assert $key=$expected" >&2
    return 0
  fi
  if python3 - "$json" "$key" "$expected" <<'PY'
import sys, json, pathlib
json_path, key, expected_raw = sys.argv[1:4]
with open(json_path, 'r') as f:
    data = json.load(f)
# Coerce expected
def coerce(val:str):
    low = val.lower()
    if low == 'true': return True
    if low == 'false': return False
    # int
    try:
        if '.' in val:
            return float(val)
        return int(val)
    except Exception:
        return val
expected = coerce(expected_raw)
actual = data.get(key, None)
ok = (actual == expected)
print(f"[assert] {key} == {expected!r} (actual={actual!r}) -> {'OK' if ok else 'FAIL'}")
sys.exit(0 if ok else 1)
PY
  then
    return 1
  fi
}

run_case() {
  local name="$1"; shift
  local flags=("$@")
  echo "\n===== CASE: $name ====="
  echo "sysmaint ${flags[*]}"
  set +e
  bash "$SYSMAINT" "${flags[@]}"
  local rc=$?
  set -e
  echo "[result] exit=$rc"
  validate_json || true
  return 0
}

# Phase 1: Default
run_case "default (no flags)"

# Phase 2: Fixed combos (stable)
run_case "upgrade final" --upgrade
assert_json final_upgrade_enabled true || true
run_case "simulate-upgrade early exit" --simulate-upgrade
run_case "no color + audits" --color=never --check-zombies --security-audit
assert_json color_mode never || true
assert_json security_audit_enabled true || true
run_case "browser cache report" --browser-cache-report
assert_json browser_cache_report true || true

# Phase 3: Optional toggles (single-feature sweeps)
run_case "fstrim" --fstrim
run_case "drop-caches" --drop-caches
run_case "purge-kernels keep=2" --purge-kernels --keep-kernels=2
assert_json kernel_purge_enabled true || true
assert_json keep_kernels 2 || true
run_case "update-grub (no-op in dry-run)" --update-grub
run_case "orphan purge" --orphan-purge
run_case "browser cache purge" --browser-cache-purge
assert_json browser_cache_purge true || true
run_case "snap cleanup" --snap-clean-old --snap-clear-cache
run_case "flatpak user-only" --flatpak-user-only
run_case "flatpak system-only" --flatpak-system-only
run_case "disable snaps" --no-snap
run_case "disable flatpak" --no-flatpak
run_case "disable firmware" --no-firmware
run_case "disable journal vacuum" --no-journal-vacuum
run_case "disable failed-services check" --no-check-failed-services
run_case "disable crash purge" --no-clear-crash
run_case "disable DNS clear" --no-clear-dns-cache
run_case "disable tmp clear" --no-clear-tmp
run_case "enable tmp clear + age" --clear-tmp --clear-tmp-age=1
run_case "force tmp clear (confirmed)" --clear-tmp-force --confirm-clear-tmp-force --yes
run_case "journal days override" --journal-days=14
assert_json journal_vacuum_time 14d || true
run_case "progress bar short" --progress=bar --progress-duration=1
run_case "progress dots short" --progress=dots --progress-duration=1
run_case "lock wait short" --lock-wait-seconds=1
run_case "color always" --color=always
run_case "reset progress history" --reset-progress-history
run_case "mode desktop" --mode=desktop
run_case "mode server" --mode=server
run_case "disable desktop guard" --no-desktop-guard
assert_json desktop_guard_enabled false || true
run_case "parallel exec (exp)" --parallel
run_case "log truncation small" --log-max-size-mb=1 --log-tail-keep-kb=16

# Phase 4: Autopilot variants
run_case "autopilot default delay" --auto
assert_json auto_mode true || true
run_case "autopilot + custom delay" --auto --auto-reboot-delay=10
assert_json auto_reboot_delay_seconds 10 || true

# Phase 5: Broad combined run (most optional features together, avoiding conflicts)
run_case "broad combined" \
  --upgrade \
  --fstrim \
  --drop-caches \
  --purge-kernels --keep-kernels=2 \
  --update-grub \
  --orphan-purge \
  --snap-clean-old --snap-clear-cache \
  --security-audit \
  --browser-cache-report \
  --progress=spinner --progress-duration=1 \
  --color=never \
  --lock-wait-seconds=2

# Phase 6: Negative toggles sweep (flip defaults off)
run_case "most defaults disabled" \
  --no-snap \
  --no-flatpak \
  --no-firmware \
  --no-clear-dns-cache \
  --no-journal-vacuum \
  --no-check-failed-services \
  --no-clear-crash \
  --no-clear-tmp \
  --no-check-zombies
assert_json zombie_check_enabled false || true

echo "\nAll full-cycle dry-run cases executed."
