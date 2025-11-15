#!/usr/bin/env bash
# Ensure the JSON schema validator rejects malformed summaries.

set -euo pipefail
cd "$(dirname "$0")/.."

SCHEMA="docs/schema/sysmaint-summary.schema.json"
INVALID_JSON="$(mktemp)"
trap 'rm -f "$INVALID_JSON"' EXIT

cat >"$INVALID_JSON" <<'JSON'
{
  "schema_version": "1.0",
  "script_version": "2.1.1"
}
JSON

if python3 tests/validate_json.py "$SCHEMA" "$INVALID_JSON" >/tmp/json_negative.log 2>&1; then
  cat /tmp/json_negative.log >&2 || true
  echo "ERROR: Validator unexpectedly accepted malformed JSON" >&2
  exit 1
fi

echo "Negative JSON schema test passed (validator rejected malformed input)."
