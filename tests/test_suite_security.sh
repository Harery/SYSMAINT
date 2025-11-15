#!/usr/bin/env bash
# test_suite_security.sh - Security Audit Test Suite for sysmaint
# Copyright (c) 2025 Mohamed Elharery <Mohamed@Harery.com>
# License: MIT
#
# Tests security audit functionality:
# - Permission checks for critical files
# - Shadow/gshadow validation
# - Sudoers configuration verification
# - Security warnings and reporting

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
  rm -rf /tmp/sysmaint-security-test-*
}

trap cleanup EXIT

# ==============================================================================
# Test 1: Security audit disabled by default
# ==============================================================================
run_test "Security audit disabled by default"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run 2>&1 || true)
if echo "$output" | grep -q "Security audit"; then
  fail "Security audit ran when not requested"
else
  pass "Security audit correctly disabled by default"
fi

# ==============================================================================
# Test 2: Security audit enabled with flag
# ==============================================================================
run_test "Security audit enabled with --security-audit flag"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --security-audit 2>&1 || true)
if echo "$output" | grep -q "=== Security audit start ==="; then
  pass "Security audit runs with --security-audit flag"
else
  fail "Security audit did not run with --security-audit flag"
fi

# ==============================================================================
# Test 3: Security audit enabled with environment variable
# ==============================================================================
run_test "Security audit enabled with SECURITY_AUDIT_ENABLED=true"
output=$(DRY_RUN=true SECURITY_AUDIT_ENABLED=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run 2>&1 || true)
if echo "$output" | grep -q "=== Security audit start ==="; then
  pass "Security audit runs with SECURITY_AUDIT_ENABLED=true"
else
  fail "Security audit did not run with SECURITY_AUDIT_ENABLED=true"
fi

# ==============================================================================
# Test 4: JSON output includes security audit fields
# ==============================================================================
run_test "JSON output includes security audit fields"
json_file="/tmp/sysmaint-security-test-$$.json"
DRY_RUN=true JSON_SUMMARY=true bash "$SYSMAINT" --dry-run --security-audit >/dev/null 2>&1 || true
# Find the JSON file
json_file=$(find /tmp/system-maintenance -name "sysmaint_*.json" -type f | tail -1)
if [[ -f "$json_file" ]]; then
  if grep -q '"security_audit_enabled"' "$json_file" && \
     grep -q '"shadow_perms_ok"' "$json_file" && \
     grep -q '"gshadow_perms_ok"' "$json_file" && \
     grep -q '"sudoers_perms_ok"' "$json_file"; then
    pass "JSON contains all security audit fields"
  else
    fail "JSON missing security audit fields"
  fi
else
  fail "JSON file not created"
fi

# ==============================================================================
# Test 5: Security audit reports permission status
# ==============================================================================
run_test "Security audit reports permission status"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --security-audit 2>&1 || true)
if echo "$output" | grep -q "Security audit results:"; then
  pass "Security audit reports results"
else
  fail "Security audit did not report results"
fi

# ==============================================================================
# Test 6: Security audit checks shadow file
# ==============================================================================
run_test "Security audit checks /etc/shadow"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --security-audit 2>&1 || true)
if echo "$output" | grep -q "shadow_ok="; then
  pass "Security audit checks /etc/shadow"
else
  fail "Security audit did not check /etc/shadow"
fi

# ==============================================================================
# Test 7: Security audit checks gshadow file
# ==============================================================================
run_test "Security audit checks /etc/gshadow"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --security-audit 2>&1 || true)
if echo "$output" | grep -q "gshadow_ok="; then
  pass "Security audit checks /etc/gshadow"
else
  fail "Security audit did not check /etc/gshadow"
fi

# ==============================================================================
# Test 8: Security audit checks sudoers file
# ==============================================================================
run_test "Security audit checks /etc/sudoers"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --security-audit 2>&1 || true)
if echo "$output" | grep -q "sudoers_ok="; then
  pass "Security audit checks /etc/sudoers"
else
  fail "Security audit did not check /etc/sudoers"
fi

# ==============================================================================
# Test 9: Security audit checks sudoers.d directory
# ==============================================================================
run_test "Security audit checks /etc/sudoers.d"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --security-audit 2>&1 || true)
if echo "$output" | grep -q "sudoers.d_issues="; then
  pass "Security audit checks /etc/sudoers.d"
else
  fail "Security audit did not check /etc/sudoers.d"
fi

# ==============================================================================
# Test 10: Security audit combines with other flags
# ==============================================================================
run_test "Security audit combines with --upgrade --check-zombies"
output=$(DRY_RUN=true JSON_SUMMARY=false CHECK_ZOMBIES=true bash "$SYSMAINT" --dry-run --security-audit --upgrade --check-zombies 2>&1 || true)
if echo "$output" | grep -q "=== Security audit start ==="; then
  pass "Security audit combines with other features"
else
  fail "Security audit did not combine properly"
fi

# ==============================================================================
# Summary
# ==============================================================================
echo ""
echo "========================================"
echo "Security Audit Test Suite Results"
echo "========================================"
echo "Total:  $TOTAL"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo ""

if [[ $FAILED -eq 0 ]]; then
  echo "✅ ALL SECURITY TESTS PASSED"
  exit 0
else
  echo "❌ SOME SECURITY TESTS FAILED"
  exit 1
fi
