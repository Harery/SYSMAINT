#!/usr/bin/env bash
# CLI Flag Duplication Matrix generator (normalized)
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
OUT_FILE="$REPO_ROOT/docs/FLAG_DUPLICATION.md"

SUITES=(
  test_suite_smoke.sh
  test_suite_edge.sh
  test_suite_security.sh
  test_suite_governance.sh
  test_suite_compliance.sh
  test_suite_performance.sh
  test_suite_combos.sh
  test_suite_realmode.sh
)

declare -A SUITE_CONTENT
for s in "${SUITES[@]}"; do
  path="$SCRIPT_DIR/$s"
  [[ -f "$path" ]] && SUITE_CONTENT["$s"]="$(cat "$path")" || SUITE_CONTENT["$s"]=""
done

extract_flags() {
  local text="$1"
  printf '%s' "$text" | grep -oE -- '--[A-Za-z0-9][A-Za-z0-9-]*(=[^[:space:]]+)?' || true
}

normalize_flag() {
  local raw="$1"
  local f
  f=$(echo "$raw" | sed 's/^["(]*//; s/["),;]*$//')
  if [[ $f =~ ^--[A-Za-z0-9][A-Za-z0-9-]*(=[^[:space:]]+)?$ ]]; then
    echo "$f"
  fi
}

declare -A FLAG_SET
for s in "${SUITES[@]}"; do
  while read -r flag; do
    norm=$(normalize_flag "$flag" || true)
    [[ -n "$norm" ]] && FLAG_SET["$norm"]=1
  done < <(extract_flags "${SUITE_CONTENT[$s]}")
done

ALL_FLAGS=$(printf '%s\n' "${!FLAG_SET[@]}" | sort -u)

{
  echo "# CLI Flag Duplication Matrix"
  echo "Generated: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "Suites: ${#SUITES[@]}"
  echo ""
  echo "| Flag | Smoke | Edge | Security | Governance | Compliance | Performance | Combos | RealMode |"
  echo "|------|:-----:|:----:|:--------:|:----------:|:----------:|:-----------:|:------:|:-------:|"
  for flag in $ALL_FLAGS; do
    row="| $flag"
    for s in "${SUITES[@]}"; do
      if printf '%s' "${SUITE_CONTENT[$s]}" | grep -F -q -- "$flag"; then row+=" | ✅"; else row+=" | "; fi
    done
    row+=" |"
    echo "$row"
  done
  echo ""
  echo "## Summary"
  echo "- Total unique flags: $(printf '%s\n' "$ALL_FLAGS" | wc -l | awk '{print $1}')"
  echo "- Legacy full-cycle suite deprecated (see legacy folder)."
  echo "- Normalization: quotes/parens/punctuation removed; canonical pattern enforced."
} > "$OUT_FILE"

echo "Updated $OUT_FILE"
