#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

OUT="${1:-coverage-matrix.json}"

declare -A suite_files=(
  [smoke]=tests/test_suite_smoke.sh
  [edge]=tests/test_suite_edge.sh
  [combos]=tests/test_suite_combos.sh
  [governance]=tests/test_suite_governance.sh
  [compliance]=tests/test_suite_compliance.sh
  [security]=tests/test_suite_security.sh
  [scanners]=tests/test_suite_scanners.sh
  [scanner_performance]=tests/test_suite_scanner_performance.sh
  [performance]=tests/test_suite_performance.sh
  [realmodesandbox]=tests/test_suite_realmode.sh
  [json_validation]=tests/test_json_validation.sh
  [json_checksum]=tests/test_json_checksum.sh
)

count_tests() {
  local file="$1"
  [[ -f "$file" ]] || { echo 0; return; }
  local c=0
  # Pattern variations across suites
  # 1. Explicit header echo lines: [Test X/Y]
  c=$(grep -E '^echo "\[Test [0-9]+/' "$file" 2>/dev/null | wc -l || true)
  # 2. Suite result blocks: capture total from e.g., 'Combo Suite Results: Passed=28 Failed=0 Total=28'
  if grep -q 'Total=' "$file" 2>/dev/null; then
    local t_line
    t_line=$(grep -E 'Total=' "$file" | tail -n1 || true)
    local t_val
    t_val=$(sed -n 's/.*Total=\([0-9]\+\).*/\1/p' <<<"$t_line" || true)
    if [[ -n "$t_val" && "$t_val" =~ ^[0-9]+$ && $t_val -gt $c ]]; then
      c=$t_val
    fi
  fi
  # 3. Count test function definitions (test_*()) if still zero
  if (( c == 0 )); then
    c=$(grep -E '^test_[a-zA-Z0-9_]+\s*\(\)' "$file" 2>/dev/null | wc -l || true)
  fi
  echo "$c"
}

total=0
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
echo '{' > "$tmp"
for suite in "${!suite_files[@]}"; do
  f="${suite_files[$suite]}"
  c=$(count_tests "$f")
  total=$((total + c))
  echo "  \"$suite\": $c," >> "$tmp"
done
echo "  \"total\": $total" >> "$tmp"
echo '}' >> "$tmp"
mv "$tmp" "$OUT"
echo "Coverage matrix written to $OUT (total=$total)" >&2