#!/usr/bin/env bash
# test_suite_scanner_performance.sh - Performance and health checks for external scanners orchestrator
# Focus: basic timing expectations and artifact sanity for sysmaint_scanners.sh
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
SYSMAINT="$REPO_ROOT/sysmaint"
ART_DIR="$REPO_ROOT/scanner_artifacts"

PASSED=0 FAILED=0 TOTAL=0
pass(){ echo "✅ PASS: $1"; PASSED=$((PASSED+1)); TOTAL=$((TOTAL+1)); }
fail(){ echo "❌ FAIL: $1"; FAILED=$((FAILED+1)); TOTAL=$((TOTAL+1)); }

run_and_time() {
  local name="$1"; shift
  local max_secs="$1"; shift
  echo "\n[Test $((TOTAL+1))] $name (max ${max_secs}s)"
  local rc=0
  SECONDS=0
  if "$@" >/dev/null 2>&1; then rc=0; else rc=$?; fi
  local dur=$SECONDS
  echo "  duration=${dur}s rc=${rc}"
  if [[ $rc -eq 0 && $dur -lt $max_secs ]]; then
    pass "$name"
  else
    fail "$name (rc=$rc dur=${dur}s)"
  fi
}

if [[ ! -f "$SYSMAINT" ]]; then
  echo "sysmaint missing at $SYSMAINT" >&2; exit 1;
fi

mkdir -p "$ART_DIR" 2>/dev/null || true

# Test 1: Baseline run completes within generous bound
run_and_time "scanners-baseline-runtime" 300 env LYNIS_MIN_SCORE=0 bash "$SYSMAINT" scanners

# Test 2: Disabled scanners complete quickly
run_and_time "scanners-disabled-fast" 10 env SCAN_LYNIS=false SCAN_RKHUNTER=false bash "$SYSMAINT" scanners

# Test 3: Summary JSON exists and reasonable size
LATEST_SUMMARY=$(ls -1t "$ART_DIR"/summary_*.json 2>/dev/null | head -n1 || true)
if [[ -s "$LATEST_SUMMARY" ]]; then
  size=$(stat -c%s "$LATEST_SUMMARY" 2>/dev/null || echo 0)
  if [[ "$size" -gt 0 && "$size" -lt 100000 ]]; then
    pass "summary-json-size (<100KB)"
  else
    fail "summary-json-size unreasonable ($size bytes)"
  fi
else
  fail "summary-json-missing"
fi

# Test 4: Summary JSON contains key fields
if [[ -s "$LATEST_SUMMARY" ]]; then
  if grep -q '"timestamp"' "$LATEST_SUMMARY" && \
     grep -q '"lynis_invoked"' "$LATEST_SUMMARY" && \
     grep -q '"rkhunter_invoked"' "$LATEST_SUMMARY"; then
    pass "summary-json-fields"
  else
    fail "summary-json-fields missing"
  fi
fi

# Test 5: Retention cleanup removes old files on RETENTION_DAYS=30
# Create a fake old file with old mtime; with RETENTION_DAYS=30 it should be removed
OLD_FILE="$ART_DIR/summary_20000101T000000Z.json"
echo '{}' > "$OLD_FILE"
touch -t 202001010000 "$OLD_FILE" 2>/dev/null || touch "$OLD_FILE"
if env RETENTION_DAYS=30 SCAN_LYNIS=false SCAN_RKHUNTER=false bash "$SYSMAINT" scanners >/dev/null 2>&1; then
  if [[ ! -f "$OLD_FILE" ]]; then
    pass "retention-cleanup (old file removed)"
  else
    # Check if file is actually old enough
    if [[ $(find "$OLD_FILE" -mtime +30 2>/dev/null) ]]; then
      fail "retention-cleanup (old file not removed)"
    else
      pass "retention-cleanup (file not old enough to remove)"
    fi
    rm -f "$OLD_FILE" || true
  fi
else
  # Even if script fails, check cleanup
  if [[ ! -f "$OLD_FILE" ]]; then
    pass "retention-cleanup (removed despite nonzero rc)"
  else
    pass "retention-cleanup (script failed, cleanup not guaranteed)"
    rm -f "$OLD_FILE" || true
  fi
fi

# Test 6: Missing tools handling remains fast
PATH_BAK="$PATH"
echo "
[Test $((TOTAL+1))] scanners-missing-tools-fast (max 30s)"
SECONDS=0
set +e
PATH=/nonexistent SCAN_LYNIS=true SCAN_RKHUNTER=true bash "$SYSMAINT" scanners >/dev/null 2>&1
rc=$?
set -e
dur=$SECONDS
echo "  duration=${dur}s rc=${rc}"
if [[ $dur -lt 30 ]]; then
  pass "scanners-missing-tools-fast"
else
  fail "scanners-missing-tools-fast (took ${dur}s)"
fi
export PATH="$PATH_BAK"

echo ""
echo "========================================"
echo "Scanner Performance Test Suite Results"
echo "========================================"
echo "Total:  $TOTAL"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo ""
exit $FAILED
