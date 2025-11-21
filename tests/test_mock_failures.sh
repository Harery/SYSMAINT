#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== Mock Failure Injection Test ==="
LIST="${REALMODE_FAIL_LIST:-apt,dpkg,snap}"
echo "Fail list: $LIST"
export REALMODE_FAIL_LIST="$LIST"

DRY_RUN=false JSON_SUMMARY=true bash sysmaint --dry-run --json-summary >/dev/null 2>&1 || true

JSON_FILE=$(ls -1t /tmp/system-maintenance/sysmaint_*.json 2>/dev/null | head -n1 || true)
if [[ -z "$JSON_FILE" ]]; then
  echo "❌ FAIL: No JSON summary generated"; exit 1
fi

# Validate that script completes even with failures (non-fatal mock exit codes) by checking presence of run_id
if ! grep -q '"run_id"' "$JSON_FILE"; then
  echo "❌ FAIL: run_id missing in JSON after mock failures"; exit 1
fi

echo "✅ PASS: JSON summary present despite injected mock failures"
exit 0