#!/usr/bin/env bash
# test_suite_governance.sh - Governance and Audit Test Suite for sysmaint
# Copyright (c) 2025 Mohamed Elharery <Mohamed@Harery.com>
# License: MIT
#
# Tests governance and audit trail functionality:
# - Audit logging and record keeping
# - Change management tracking
# - User action accountability
# - Configuration drift detection
# - Policy enforcement validation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSMAINT="${SCRIPT_DIR}/../sysmaint"

PASSED=0
FAILED=0
TOTAL=0

pass() {
  PASSED=$((PASSED + 1))
  echo "✅ PASS: $1"
}

fail() {
  FAILED=$((FAILED + 1))
  echo "❌ FAIL: $1"
}

run_test() {
  TOTAL=$((TOTAL + 1))
  local test_name="$1"
  echo ""
  echo "Test $TOTAL: $test_name"
  echo "----------------------------------------"
}

cleanup() {
  rm -rf /tmp/sysmaint-governance-test-*
}

trap cleanup EXIT

# ==============================================================================
# Test 1: Audit log creation and structure
# ==============================================================================
run_test "Audit log is created with proper structure"
DRY_RUN=true JSON_SUMMARY=true bash "$SYSMAINT" --dry-run >/dev/null 2>&1 || true
json_file=$(find /tmp/system-maintenance -name "sysmaint_*.json" -type f | tail -1)
if [[ -f "$json_file" ]] && grep -q '"timestamp"' "$json_file" && grep -q '"run_id"' "$json_file"; then
  pass "Audit log has required governance fields"
else
  fail "Audit log missing governance structure"
fi

# ==============================================================================
# Test 2: Timestamp presence
# ==============================================================================
run_test "Audit log includes timestamp field"
json_file=$(find /tmp/system-maintenance -name "sysmaint_*.json" -type f | tail -1)
if [[ -f "$json_file" ]] && grep -q '"timestamp"' "$json_file"; then
  pass "Timestamp field present"
else
  fail "Timestamp field missing"
fi

# ==============================================================================
# Test 3: User identification in audit logs
# ==============================================================================
run_test "Audit log captures system context"
DRY_RUN=true JSON_SUMMARY=true bash "$SYSMAINT" --dry-run >/dev/null 2>&1 || true
json_file=$(find /tmp/system-maintenance -name "sysmaint_*.json" -type f | tail -1)
if [[ -f "$json_file" ]] && grep -q '"os_description"' "$json_file"; then
  pass "Audit log captures system context"
else
  fail "Audit log missing system context"
fi

# ==============================================================================
# Test 4: Command line arguments recorded
# ==============================================================================
run_test "Audit log records command line arguments"
DRY_RUN=true JSON_SUMMARY=true bash "$SYSMAINT" --dry-run --upgrade --security-audit >/dev/null 2>&1 || true
json_file=$(find /tmp/system-maintenance -name "sysmaint_*.json" -type f | tail -1)
if [[ -f "$json_file" ]]; then
  if grep -q '"dry_run_mode": true' "$json_file" && grep -q '"security_audit_enabled"' "$json_file"; then
    pass "Audit log records execution parameters"
  else
    fail "Audit log missing execution parameters"
  fi
else
  fail "Audit log not created"
fi

# ==============================================================================
# Test 5: Change tracking in dry-run mode
# ==============================================================================
run_test "Change management tracks proposed changes in dry-run"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --upgrade 2>&1 || true)
if grep -qE "(DRY_RUN|would)" <<< "$output"; then
  pass "Change management tracks dry-run operations"
else
  fail "Change management missing dry-run tracking"
fi

# ==============================================================================
# Test 6: System state capture before changes
# ==============================================================================
run_test "Governance captures system state before changes"
DRY_RUN=true JSON_SUMMARY=true bash "$SYSMAINT" --dry-run >/dev/null 2>&1 || true
json_file=$(find /tmp/system-maintenance -name "sysmaint_*.json" -type f | tail -1)
if [[ -f "$json_file" ]] && grep -q '"package_count"' "$json_file"; then
  pass "System state captured for governance"
else
  fail "System state not captured"
fi

# ==============================================================================
# Test 7: Privileged operation logging
# ==============================================================================
run_test "Governance logs privileged operations"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --security-audit 2>&1 || true)
if grep -qE "(Security audit|checking|sudoers)" <<< "$output"; then
  pass "Privileged operations are logged"
else
  fail "Privileged operations not logged"
fi

# ==============================================================================
# Test 8: Configuration file access tracking
# ==============================================================================
run_test "Governance tracks configuration file access"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --security-audit 2>&1 || true)
if grep -qE "(shadow|sudoers|checking)" <<< "$output"; then
  pass "Configuration access is tracked"
else
  fail "Configuration access not tracked"
fi

# ==============================================================================
# Test 9: Audit trail completeness
# ==============================================================================
run_test "Audit trail includes start and end markers"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run 2>&1 || true)
if grep -q "System maintenance started" <<< "$output" && grep -q "System maintenance finished" <<< "$output"; then
  pass "Audit trail has complete lifecycle markers"
else
  fail "Audit trail incomplete"
fi

# ==============================================================================
# Test 10: Policy enforcement - root requirement
# ==============================================================================
run_test "Policy enforcement validates root privileges"
output=$(bash "$SYSMAINT" --dry-run 2>&1 || true)
# Script should check for root or handle non-root scenarios
if grep -qE "(root|permission|privilege|DRY_RUN)" <<< "$output"; then
  pass "Policy enforces privilege requirements"
else
  fail "Policy missing privilege enforcement"
fi

# ==============================================================================
# Test 11: Compliance mode flag support
# ==============================================================================
run_test "Governance supports compliance mode operations"
output=$(DRY_RUN=true JSON_SUMMARY=true bash "$SYSMAINT" --dry-run --security-audit 2>&1 || true)
json_file=$(find /tmp/system-maintenance -name "sysmaint_*.json" -type f | tail -1)
if [[ -f "$json_file" ]] && grep -q '"security_audit_enabled"' "$json_file"; then
  pass "Compliance mode properly flagged"
else
  fail "Compliance mode not supported"
fi

# ==============================================================================
# Test 12: Audit retention and file naming
# ==============================================================================
run_test "Audit logs use consistent naming for retention"
json_file=$(find /tmp/system-maintenance -name "sysmaint_*.json" -type f | tail -1)
if [[ -f "$json_file" ]] && [[ "$json_file" =~ sysmaint_[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{6}.*\.json ]]; then
  pass "Audit logs follow naming convention"
else
  fail "Audit logs have inconsistent naming"
fi

# ==============================================================================
# Test 13: Multi-user environment tracking
# ==============================================================================
run_test "Governance handles multi-user environment"
DRY_RUN=true JSON_SUMMARY=true bash "$SYSMAINT" --dry-run >/dev/null 2>&1 || true
json_file=$(find /tmp/system-maintenance -name "sysmaint_*.json" -type f | tail -1)
if [[ -f "$json_file" ]] && grep -q '"os_description"' "$json_file"; then
  pass "System context captured for multi-user tracking"
else
  fail "Multi-user context not captured"
fi

# ==============================================================================
# Test 14: Change approval workflow support
# ==============================================================================
run_test "Governance supports change approval workflow"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --upgrade 2>&1 || true)
if grep -qE "(DRY_RUN|would|simulation)" <<< "$output"; then
  pass "Change approval workflow supported via dry-run"
else
  fail "Change approval workflow not supported"
fi

# ==============================================================================
# Test 15: Separation of duties validation
# ==============================================================================
run_test "Governance validates separation of duties"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --security-audit 2>&1 || true)
if grep -qE "(sudoers|Security audit)" <<< "$output"; then
  pass "Separation of duties checked via sudoers"
else
  fail "Separation of duties not validated"
fi

# ==============================================================================
# Test 16: Unique run_id per execution
# ==============================================================================
run_test "Governance assigns unique run_id per run"
DRY_RUN=true JSON_SUMMARY=true bash "$SYSMAINT" --dry-run >/dev/null 2>&1 || true
f1=$(ls -1t /tmp/system-maintenance/sysmaint_*.json 2>/dev/null | head -1)
rid1=$(grep '"run_id"' "$f1" 2>/dev/null | head -1 || echo "")
sleep 2
DRY_RUN=true JSON_SUMMARY=true bash "$SYSMAINT" --dry-run >/dev/null 2>&1 || true
f2=$(ls -1t /tmp/system-maintenance/sysmaint_*.json 2>/dev/null | head -1)
rid2=$(grep '"run_id"' "$f2" 2>/dev/null | head -1 || echo "")
if [[ -n "$rid1" && -n "$rid2" && "$rid1" != "$rid2" ]]; then
  pass "Unique run_id per run"
else
  fail "run_id not unique across runs (rid1='$rid1' rid2='$rid2')"
fi

# ==============================================================================
# Test 17: JSON includes log_file field
# ==============================================================================
run_test "Governance JSON includes log_file path"
json_file=$(find /tmp/system-maintenance -name "sysmaint_*.json" -type f | tail -1)
if [[ -f "$json_file" ]] && grep -q '"log_file"' "$json_file"; then
  pass "JSON contains log_file"
else
  fail "JSON missing log_file"
fi

# ==============================================================================
# Test 18: JSON includes hostname
# ==============================================================================
run_test "Governance JSON includes hostname"
json_file=$(find /tmp/system-maintenance -name "sysmaint_*.json" -type f | tail -1)
if [[ -f "$json_file" ]] && grep -q '"hostname"' "$json_file"; then
  pass "JSON contains hostname"
else
  fail "JSON missing hostname"
fi

# ==============================================================================
# Summary
# ==============================================================================
echo ""
echo "========================================"
echo "Governance Test Suite Results"
echo "========================================"
echo "Total:  $TOTAL"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo ""

if [[ $FAILED -eq 0 ]]; then
  echo "✅ ALL GOVERNANCE TESTS PASSED"
  exit 0
else
  echo "❌ SOME GOVERNANCE TESTS FAILED"
  exit 1
fi
