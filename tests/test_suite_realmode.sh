#!/usr/bin/env bash
# Modernized Real-Mode Integration Suite
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
SYSMAINT="$REPO_ROOT/sysmaint"
SANDBOX_BIN="$REPO_ROOT/tests/mocks/realmodesandbox/bin"
[[ -d "$SANDBOX_BIN" ]] || { echo "Sandbox bin missing" >&2; exit 1; }
export PATH="$SANDBOX_BIN:$PATH" SYSMAINT_FAKE_ROOT=1 JSON_SUMMARY=true
unset DRY_RUN
LOG_DIR="${LOG_DIR:-/tmp/system-maintenance}"; export LOG_DIR; mkdir -p "$LOG_DIR"
PASSED=0 FAILED=0 TOTAL=0
verify(){ python3 - "$1" <<'PY' || return 1
import json,sys
f=sys.argv[1]
with open(f) as fh: d=json.load(fh)
for k in ['run_id','hostname','zombie_count','dry_run_mode']: assert k in d, k
int(str(d['zombie_count']))
PY }
run_case(){ local name="$1"; shift; TOTAL=$((TOTAL+1)); echo "[REALMODE $TOTAL] $name";
  local rid="real_${name}_$(date +%s)_$RANDOM" json="$LOG_DIR/sysmaint_${rid}.json"
  if RUN_ID="$rid" "$SYSMAINT" "$@" >/dev/null 2>&1; then
    if [[ -s "$json" ]] && verify "$json"; then echo "✅ $name"; PASSED=$((PASSED+1)); else echo "❌ $name (verify)"; FAILED=$((FAILED+1)); fi
  else echo "❌ $name (exec)"; FAILED=$((FAILED+1)); fi }
run_case default --json-summary
run_case upgrade --upgrade --json-summary
run_case security --security-audit --check-zombies --json-summary
run_case browser --browser-cache-report --browser-cache-purge --json-summary
run_case auto --auto --auto-reboot-delay=45 --json-summary
echo "Real-mode Suite: Passed=$PASSED Failed=$FAILED Total=$TOTAL"; exit $FAILED
