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
echo "[Test 1/2] Validating real sysmaint JSON output..."
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

# Test 2: Negative validation (malformed JSON should be rejected)
echo "[Test 2/2] Verifying validator rejects malformed JSON..."
INVALID_JSON="$(mktemp)"
trap 'rm -f "$INVALID_JSON"' EXIT

cat >"$INVALID_JSON" <<'JSON'
{
  "schema_version": "1.0",
  "script_version": "2.1.1"
}
JSON

if python3 tests/validate_json.py "$SCHEMA" "$INVALID_JSON" >/tmp/json_negative.log 2>&1; then
  echo "❌ FAIL: Validator unexpectedly accepted malformed JSON"
  cat /tmp/json_negative.log 2>/dev/null || true
  FAILED=$((FAILED + 1))
else
  echo "✅ PASS: Malformed JSON correctly rejected"
  PASSED=$((PASSED + 1))
fi

echo ""
echo "JSON Validation Suite: Passed=$PASSED Failed=$FAILED Total=2"
exit $FAILED
