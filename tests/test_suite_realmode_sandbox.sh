#!/usr/bin/env bash
# Real-mode sandbox suite: exercises key code paths with DRY_RUN disabled while
# intercepting privileged binaries via tests/mocks/realmodesandbox.

set -euo pipefail
cd "$(dirname "$0")/.."

ROOT_DIR="$PWD"
SANDBOX_BIN="$ROOT_DIR/tests/mocks/realmodesandbox/bin"
if [[ ! -d "$SANDBOX_BIN" ]]; then
  echo "ERROR: sandbox bin directory missing at $SANDBOX_BIN" >&2
  exit 1
fi

export PATH="$SANDBOX_BIN:$PATH"
export SYSMAINT_FAKE_ROOT=1
export JSON_SUMMARY=true
unset DRY_RUN

SCRIPT="$ROOT_DIR/sysmaint"
LOG_DIR="${LOG_DIR:-/tmp/system-maintenance}"
export LOG_DIR
mkdir -p "$LOG_DIR"

PASSED=0
FAILED=0

fail() {
  echo "❌ $1" >&2
  FAILED=$((FAILED + 1))
}

assert_json_bool() {
  local json=$1 field=$2 expected=$3
  python3 - "$json" "$field" "$expected" <<'PY'
import json, sys
path = sys.argv[2].split('.')
expected = sys.argv[3].lower() == "true"
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    data = json.load(fh)
value = data
for part in path:
    if part not in value:
        print(f"Missing field: {'.'.join(path)}", file=sys.stderr)
        sys.exit(1)
    value = value[part]
if isinstance(value, str):
    actual = value.lower() in ("true", "1", "yes")
else:
    actual = bool(value)
if actual != expected:
    print(f"Field {'.'.join(path)} mismatch: expected {expected}, got {value}", file=sys.stderr)
    sys.exit(1)
PY
}

assert_json_number() {
  local json=$1 field=$2 expected=$3
  python3 - "$json" "$field" "$expected" <<'PY'
import json, sys
path = sys.argv[2].split('.')
expected = int(sys.argv[3])
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    data = json.load(fh)
value = data
for part in path:
    if part not in value:
        print(f"Missing field: {'.'.join(path)}", file=sys.stderr)
        sys.exit(1)
    value = value[part]
try:
    actual = int(value)
except Exception:
    print(f"Field {'.'.join(path)} is not numeric: {value}", file=sys.stderr)
    sys.exit(1)
if actual != expected:
    print(f"Field {'.'.join(path)} mismatch: expected {expected}, got {actual}", file=sys.stderr)
    sys.exit(1)
PY
}

verify_real_mode() {
  local json=$1
  assert_json_bool "$json" "dry_run_mode" false
}

verify_upgrade() {
  local json=$1
  assert_json_bool "$json" "dry_run_mode" false
  assert_json_bool "$json" "final_upgrade_enabled" true
}

verify_auto() {
  local json=$1
  assert_json_bool "$json" "dry_run_mode" false
  assert_json_bool "$json" "auto_mode" true
}

verify_browser() {
  local json=$1
  assert_json_bool "$json" "dry_run_mode" false
  assert_json_bool "$json" "browser_cache_report" true
  assert_json_bool "$json" "browser_cache_purge" true
}

verify_security() {
  local json=$1
  assert_json_bool "$json" "dry_run_mode" false
  assert_json_bool "$json" "security_audit_enabled" true
  assert_json_bool "$json" "zombie_check_enabled" true
}

run_case() {
  local name="$1" verifier="$2"
  shift 2
  local run_id="sandbox_${name}_$(date +%s)_$RANDOM"
  echo "[SANDBOX] Running $name"
  if RUN_ID="$run_id" "$SCRIPT" "$@" >/tmp/sysmaint_sandbox_${name}.log 2>&1; then
    local json_file="$LOG_DIR/sysmaint_${run_id}.json"
    if [[ ! -s "$json_file" ]]; then
      fail "$name — JSON summary missing (expected $json_file)"
      return
    fi
    if "$verifier" "$json_file"; then
      echo "✅ $name"
      PASSED=$((PASSED + 1))
    else
      fail "$name — verifier reported failure"
    fi
  else
    tail -n 50 /tmp/sysmaint_sandbox_${name}.log >&2 || true
    fail "$name — sysmaint exited with code $?"
  fi
}

run_case "default-real-mode" verify_real_mode
run_case "upgrade-real-mode" verify_upgrade --upgrade
run_case "auto-real-mode" verify_auto --auto --auto-reboot-delay 45
run_case "browser-real-mode" verify_browser --browser-cache-report --browser-cache-purge
run_case "security-real-mode" verify_security --security-audit --check-zombies

echo "Sandbox suite complete: $PASSED passed, $FAILED failed"
exit $FAILED
