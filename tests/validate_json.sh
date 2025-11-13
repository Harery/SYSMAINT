#!/usr/bin/env bash
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery
set -euo pipefail
cd "$(dirname "$0")/.."

# Run a dry-run to produce JSON
DRY_RUN=true JSON_SUMMARY=true bash sysmaint --dry-run --json-summary >/dev/null 2>&1 || true
JSON_FILE=$(ls -1t /tmp/system-maintenance/sysmaint_*.json 2>/dev/null | head -n1)
if [[ -z "${JSON_FILE:-}" ]]; then
  echo "No JSON found to validate" >&2; exit 1
fi
SCHEMA=docs/schema/sysmaint-summary.schema.json
python3 tests/validate_json.py "$SCHEMA" "$JSON_FILE"
