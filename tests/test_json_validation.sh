#!/usr/bin/env bash
# JSON Schema Validation Tests (positive + negative cases)
# Author: Mohamed Elharery <Mohamed@Harery.com>
# Copyright (c) 2025 Mohamed Elharery

set -euo pipefail
cd "$(dirname "$0")/.."

SCHEMA="docs/schema/sysmaint-summary.schema.json"
PASSED=0
FAILED=0

echo "=== JSON Schema Validation Suite ==="

# Test 1: Positive validation (valid JSON from sysmaint)
echo "[Test 1/4] Validating real sysmaint JSON output..."
set +e
DRY_RUN=true JSON_SUMMARY=true bash sysmaint --dry-run --json-summary >/dev/null 2>&1
set -e
JSON_FILE=$(ls -1t /tmp/system-maintenance/sysmaint_*.json 2>/dev/null | head -n1 || true)

if [[ -z "${JSON_FILE:-}" ]]; then
  echo "❌ FAIL: No JSON found to validate"
  FAILED=$((FAILED + 1))
else
  if python3 tests/validate_json.py "$SCHEMA" "$JSON_FILE" >/dev/null 2>&1; then
    echo "✅ PASS: Valid JSON accepted by schema"
    PASSED=$((PASSED + 1))
  else
    echo "❌ FAIL: Valid JSON rejected by schema"
    FAILED=$((FAILED + 1))
  fi
fi

# Test 2: Negative validation (malformed JSON should be rejected - structure truncated)
echo "[Test 2/4] Verifying validator rejects malformed JSON (truncated)..."
INVALID_JSON="$(mktemp)"
trap 'rm -f "$INVALID_JSON"' EXIT

cat >"$INVALID_JSON" <<'JSON'
{
  "schema_version": "1.0",
  "script_version": "2.1.1"
}
JSON

if python3 tests/validate_json.py "$SCHEMA" "$INVALID_JSON" >/tmp/json_negative.log 2>&1; then
  echo "❌ FAIL: Validator unexpectedly accepted truncated JSON"
  cat /tmp/json_negative.log 2>/dev/null || true
  FAILED=$((FAILED + 1))
else
  echo "✅ PASS: Truncated JSON correctly rejected"
  PASSED=$((PASSED + 1))
fi

# Test 3: Missing required field (run_id removed)
echo "[Test 3/4] Verifying missing required field is rejected..."
MISSING_REQUIRED_JSON="$(mktemp)"
trap 'rm -f "$INVALID_JSON" "$MISSING_REQUIRED_JSON" "$WRONG_TYPE_JSON"' EXIT
cat >"$MISSING_REQUIRED_JSON" <<'JSON'
{
  "schema_version": "1.0",
  "script_version": "2.1.1",
  "timestamp": "2025-11-20T00:00:00Z",
  "disk_usage": {"before_kb": 10, "after_kb": 9, "saved_kb": 1},
  "final_upgrade_enabled": true,
  "color_mode": "auto",
  "log_truncated": false,
  "zombie_check_enabled": false,
  "zombie_count": 0,
  "security_audit_enabled": false,
  "browser_cache_report": false,
  "reboot_required": false,
  "log_file": "/tmp/fake.log"
}
JSON
if python3 tests/validate_json.py "$SCHEMA" "$MISSING_REQUIRED_JSON" >/tmp/json_missing_required.log 2>&1; then
  echo "❌ FAIL: Validator accepted JSON missing run_id"
  cat /tmp/json_missing_required.log 2>/dev/null || true
  FAILED=$((FAILED + 1))
else
  echo "✅ PASS: Missing required field correctly rejected"
  PASSED=$((PASSED + 1))
fi

# Test 4: Wrong type for a required field (script_version as number)
echo "[Test 4/4] Verifying wrong type is rejected..."
WRONG_TYPE_JSON="$(mktemp)"
cat >"$WRONG_TYPE_JSON" <<'JSON'
{
  "schema_version": "1.0",
  "script_version": 211,  
  "run_id": "abc123",
  "timestamp": "2025-11-20T00:00:00Z",
  "disk_usage": {"before_kb": 10, "after_kb": 9, "saved_kb": 1},
  "final_upgrade_enabled": true,
  "color_mode": "auto",
  "log_truncated": false,
  "zombie_check_enabled": false,
  "zombie_count": 0,
  "security_audit_enabled": false,
  "browser_cache_report": false,
  "reboot_required": false,
  "log_file": "/tmp/fake.log"
}
JSON
if python3 tests/validate_json.py "$SCHEMA" "$WRONG_TYPE_JSON" >/tmp/json_wrong_type.log 2>&1; then
  echo "❌ FAIL: Validator accepted JSON with wrong type for script_version"
  cat /tmp/json_wrong_type.log 2>/dev/null || true
  FAILED=$((FAILED + 1))
else
  echo "✅ PASS: Wrong type correctly rejected"
  PASSED=$((PASSED + 1))
fi

echo ""
echo "JSON Validation Suite: Passed=$PASSED Failed=$FAILED Total=4"
exit $FAILED
