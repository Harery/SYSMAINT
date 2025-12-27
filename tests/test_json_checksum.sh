#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== JSON Checksum Integrity Test ==="
DRY_RUN=true JSON_SUMMARY=true bash sysmaint --dry-run --json-summary >/dev/null 2>&1 || {
  echo "❌ FAIL: sysmaint invocation failed"; exit 1; }

JSON_FILE=$(ls -1t /tmp/system-maintenance/sysmaint_*.json 2>/dev/null | head -n1 || true)
if [[ -z "${JSON_FILE:-}" ]]; then
  echo "❌ FAIL: No JSON summary file found"; exit 1
fi
# Native checksum generation expected (no external injection script)

checksum_line=$(grep -E '"checksum_sha256"' "$JSON_FILE" || true)
if [[ -z "$checksum_line" ]]; then
  echo "❌ FAIL: checksum_sha256 field missing"; exit 1
fi

checksum_value=$(sed -n 's/.*"checksum_sha256": "\([a-f0-9]\{64\}\)".*/\1/p' "$JSON_FILE")
if [[ -z "$checksum_value" ]]; then
  echo "❌ FAIL: checksum value not 64 hex chars"; exit 1
fi

# Recompute by replacing checksum value with placeholder and hashing
tmp_verify=$(mktemp)
trap 'rm -f "$tmp_verify"' EXIT
sed -E 's/("checksum_sha256": ")([a-f0-9]{64})(")/\1PLACEHOLDER\3/' "$JSON_FILE" > "$tmp_verify"
recomputed=$(sha256sum "$tmp_verify" | awk '{print $1}')
if [[ "$recomputed" != "$checksum_value" ]]; then
  echo "❌ FAIL: Checksum mismatch (expected $checksum_value got $recomputed)"; exit 1
fi

echo "✅ PASS: checksum_sha256 matches base content hash"
exit 0