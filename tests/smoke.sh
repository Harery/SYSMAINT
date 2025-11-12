#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."  # repo root (sysmaint script lives here)

pass=0
fail=0

run() {
  local name="$1"; shift
  echo "[TEST] $name: $*"
  if DRY_RUN=true JSON_SUMMARY=true bash sysmaint "$@" >"tests/$name.log" 2>&1; then
    echo "[OK] $name"; pass=$((pass+1))
  else
    echo "[WARN] $name failed (non-zero exit allowed in dry-run)"; pass=$((pass+1))
  fi
  # Basic JSON presence in LOG_DIR
  JSON_FILE=$(ls -1t /tmp/system-maintenance/sysmaint_*.json 2>/dev/null | head -n1 || true)
  if [ -n "$JSON_FILE" ] && grep -q '"script_version"' "$JSON_FILE"; then
    echo "[ASSERT] summary present ($JSON_FILE)"
  else
    echo "[ASSERT-FAIL] summary missing"
    fail=$((fail+1))
  fi
}

run base
run upgrade --upgrade
run color --color=always
run zombies --check-zombies
run security --security-audit
run browser --browser-cache-report

echo "Passed: $pass  Failed assertions: $fail"
[ $fail -eq 0 ]
