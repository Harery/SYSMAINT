#!/usr/bin/env bash
# Full-cycle dry-run test suite for sysmaint
# Runs progressively: default, fixed combos, optional toggles, and a broad combined run.
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
run_case "simulate-upgrade early exit" --simulate-upgrade
run_case "no color + audits" --color=never --check-zombies --security-audit
run_case "browser cache report" --browser-cache-report

# Phase 3: Optional toggles (single-feature sweeps)
run_case "fstrim" --fstrim
run_case "drop-caches" --drop-caches
run_case "purge-kernels keep=2" --purge-kernels --keep-kernels=2
run_case "update-grub (no-op in dry-run)" --update-grub
run_case "orphan purge" --orphan-purge
run_case "browser cache purge" --browser-cache-purge
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
run_case "progress bar short" --progress=bar --progress-duration=1
run_case "lock wait short" --lock-wait-seconds=1
run_case "color always" --color=always
run_case "reset progress history" --reset-progress-history
run_case "mode desktop" --mode=desktop
run_case "mode server" --mode=server
run_case "parallel exec (exp)" --parallel
run_case "log truncation small" --log-max-size-mb=1 --log-tail-keep-kb=16

# Phase 4: Autopilot variants
run_case "autopilot default delay" --auto
run_case "autopilot + custom delay" --auto --auto-reboot-delay=10

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

echo "\nAll full-cycle dry-run cases executed."
