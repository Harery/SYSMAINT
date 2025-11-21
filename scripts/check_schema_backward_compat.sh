#!/usr/bin/env bash
set -euo pipefail
TAG=${1:-"v2.1.0"}
CURRENT="docs/schema/sysmaint-summary.schema.json"
if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq required" >&2; exit 1
fi
if ! git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "ERROR: tag $TAG not found" >&2; exit 1
fi
OLD_FILE=$(mktemp)
git show "$TAG:$CURRENT" > "$OLD_FILE" 2>/dev/null || { echo "ERROR: cannot read old schema"; exit 1; }
old_req=$(jq -r '.required[]' "$OLD_FILE" | sort)
new_req=$(jq -r '.required[]' "$CURRENT" | sort)
missing=$(comm -23 <(echo "$old_req") <(echo "$new_req") || true)
added=$(comm -13 <(echo "$old_req") <(echo "$new_req") || true)
echo "Old required count: $(echo "$old_req" | wc -l)"
echo "New required count: $(echo "$new_req" | wc -l)"
if [[ -n "$missing" ]]; then
  echo "❌ BREAKING: required keys removed:"; echo "$missing"; exit 1
fi
echo "✅ No required key removals detected"
if [[ -n "$added" ]]; then
  echo "ℹ️ Added required keys:"; echo "$added"
fi
exit 0