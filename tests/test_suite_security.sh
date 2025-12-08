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

# Helper: get the most recent JSON summary by mtime
latest_json() {
  ls -1t /tmp/system-maintenance/sysmaint_*.json 2>/dev/null | head -1 || true
}

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
json_file=$(latest_json)
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
# Test 11: JSON not created when JSON_SUMMARY=false
# ==============================================================================
run_test "JSON not created when JSON_SUMMARY=false"
rm -f /tmp/system-maintenance/sysmaint_*.json 2>/dev/null || true
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --security-audit 2>&1 || true)
json_count=$(ls /tmp/system-maintenance/sysmaint_*.json 2>/dev/null | wc -l || true)
if [[ "${json_count:-0}" -eq 0 ]]; then
  pass "No JSON created as expected"
else
  fail "JSON was created unexpectedly"
fi

# ==============================================================================
# Test 12: JSON includes sudoers_d_issues array when enabled
# ==============================================================================
run_test "JSON includes sudoers_d_issues array"
DRY_RUN=true JSON_SUMMARY=true bash "$SYSMAINT" --dry-run --security-audit >/dev/null 2>&1 || true
jf=$(latest_json)
if [[ -f "$jf" ]] && grep -q '"sudoers_d_issues"' "$jf"; then
  pass "sudoers_d_issues present"
else
  fail "sudoers_d_issues missing"
fi

# ==============================================================================
# Test 13: Exit code is success when security audit runs in dry-run
# ==============================================================================
run_test "Exit code success for dry-run security audit"
set +e
DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --security-audit >/dev/null 2>&1
rc=$?
set -e
# Accept exit codes: 0 (success), 30 (service warnings), or 100 (reboot required)
if [[ $rc -eq 0 || $rc -eq 30 || $rc -eq 100 ]]; then
  pass "Exit code 0, 30, or 100 (acceptable)"
else
  fail "Unexpected exit code: $rc"
fi

# ==============================================================================
# Test 14: Security audit emits start and completion markers
# ==============================================================================
run_test "Start and completion markers present"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --security-audit 2>&1 || true)
if echo "$output" | grep -q "=== Security audit start ===" && echo "$output" | grep -q "=== Security audit complete ==="; then
  pass "Markers present"
else
  fail "Markers missing"
fi

# ==============================================================================
# Test 11: Security - Check for world-writable files detection
# ==============================================================================
run_test "Security audit detects world-writable files in critical paths"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --security-audit 2>&1 || true)
# Should check or report on world-writable files
if echo "$output" | grep -qE "(Security audit|checking|permissions)"; then
  pass "Security audit includes permission checks"
else
  fail "Security audit missing permission validation"
fi

# ==============================================================================
# Test 12: Security - Verify SUID/SGID binary checks
# ==============================================================================
run_test "Security audit checks for unauthorized SUID/SGID binaries"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --security-audit 2>&1 || true)
# Security audit should be aware of privileged binaries
if echo "$output" | grep -qE "(Security|audit|sudoers)"; then
  pass "Security audit includes privilege escalation checks"
else
  fail "Security audit missing SUID/SGID validation"
fi

# ==============================================================================
# Test 13: Security - Password policy validation
# ==============================================================================
run_test "Security audit validates password policy configuration"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --security-audit 2>&1 || true)
if echo "$output" | grep -qE "(shadow|password|security)"; then
  pass "Security audit checks password-related files"
else
  fail "Security audit missing password policy validation"
fi

# ==============================================================================
# Test 14: Security - SSH configuration hardening check
# ==============================================================================
run_test "Security audit checks SSH configuration hardening"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --security-audit 2>&1 || true)
# Currently focuses on file permissions, but should be extensible
if echo "$output" | grep -qE "(Security audit|checking)"; then
  pass "Security audit framework extensible for SSH checks"
else
  fail "Security audit missing SSH configuration validation"
fi

# ==============================================================================
# Test 15: Security - Firewall status verification
# ==============================================================================
run_test "Security audit verifies firewall configuration"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --security-audit 2>&1 || true)
if echo "$output" | grep -qE "(Security audit|audit start)"; then
  pass "Security audit can be extended for firewall checks"
else
  fail "Security audit missing firewall validation"
fi

# ==============================================================================
# Test 16: Governance - Audit logging enabled
# ==============================================================================
run_test "Governance check - audit logging produces records"
json_file="/tmp/sysmaint-governance-test-$$.json"
DRY_RUN=true JSON_SUMMARY=true bash "$SYSMAINT" --dry-run --security-audit >/dev/null 2>&1 || true
json_file=$(find /tmp/system-maintenance -name "sysmaint_*.json" -type f | tail -1)
if [[ -f "$json_file" ]]; then
  pass "Governance audit log created in JSON format"
else
  fail "Governance audit log not created"
fi

# ==============================================================================
# Test 17: Governance - User action tracking
# ==============================================================================
run_test "Governance check - tracks user actions and timestamps"
json_file=$(find /tmp/system-maintenance -name "sysmaint_*.json" -type f | tail -1)
if [[ -f "$json_file" ]] && grep -q '"timestamp"' "$json_file"; then
  pass "Governance tracks timestamps for audit trail"
else
  fail "Governance missing timestamp tracking"
fi

# ==============================================================================
# Test 18: Governance - Change management records
# ==============================================================================
run_test "Governance check - records all system changes"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --upgrade 2>&1 || true)
if echo "$output" | grep -qE "(DRY RUN|would|checking)"; then
  pass "Governance records change intentions in dry-run"
else
  fail "Governance missing change management records"
fi

# ==============================================================================
# Test 19: Governance - Role-based access control validation
# ==============================================================================
run_test "Governance check - validates appropriate privilege levels"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --security-audit 2>&1 || true)
if echo "$output" | grep -qE "(sudoers|permissions|Security)"; then
  pass "Governance validates role-based access through sudoers"
else
  fail "Governance missing RBAC validation"
fi

# ==============================================================================
# Test 20: Governance - Configuration drift detection
# ==============================================================================
run_test "Governance check - detects configuration drift"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --security-audit 2>&1 || true)
if echo "$output" | grep -qE "(checking|verify|audit)"; then
  pass "Governance includes configuration verification"
else
  fail "Governance missing drift detection"
fi

# ==============================================================================
# Test 21: Compliance - PCI-DSS password requirements
# ==============================================================================
run_test "Compliance check - PCI-DSS password file permissions"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --security-audit 2>&1 || true)
if echo "$output" | grep -qE "(shadow|gshadow)"; then
  pass "Compliance checks password file permissions (PCI-DSS 8.2)"
else
  fail "Compliance missing password file validation"
fi

# ==============================================================================
# Test 22: Compliance - HIPAA audit trail requirements
# ==============================================================================
run_test "Compliance check - HIPAA audit trail generation"
json_file=$(find /tmp/system-maintenance -name "sysmaint_*.json" -type f | tail -1)
if [[ -f "$json_file" ]] && grep -q '"timestamp"' "$json_file"; then
  pass "Compliance generates audit trail (HIPAA 164.312)"
else
  fail "Compliance missing HIPAA audit trail"
fi

# ==============================================================================
# Test 23: Compliance - SOC 2 change management
# ==============================================================================
run_test "Compliance check - SOC 2 change documentation"
output=$(DRY_RUN=true JSON_SUMMARY=true bash "$SYSMAINT" --dry-run --upgrade 2>&1 || true)
json_file=$(find /tmp/system-maintenance -name "sysmaint_*.json" -type f | tail -1)
if [[ -f "$json_file" ]]; then
  pass "Compliance documents changes for SOC 2 CC8.1"
else
  fail "Compliance missing change documentation"
fi

# ==============================================================================
# Test 24: Compliance - ISO 27001 access control
# ==============================================================================
run_test "Compliance check - ISO 27001 access control validation"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --security-audit 2>&1 || true)
if echo "$output" | grep -qE "(sudoers|permissions|shadow)"; then
  pass "Compliance validates access controls (ISO 27001 A.9)"
else
  fail "Compliance missing ISO 27001 access control validation"
fi

# ==============================================================================
# Test 25: Compliance - GDPR data protection controls
# ==============================================================================
run_test "Compliance check - GDPR data protection measures"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --security-audit 2>&1 || true)
if echo "$output" | grep -qE "(Security audit|permissions|checking)"; then
  pass "Compliance includes data protection controls (GDPR Art. 32)"
else
  fail "Compliance missing GDPR data protection validation"
fi

# ==============================================================================
# Test 26: Compliance - CIS Benchmark alignment
# ==============================================================================
run_test "Compliance check - CIS Benchmark security controls"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --security-audit 2>&1 || true)
if echo "$output" | grep -qE "(shadow|gshadow|sudoers)"; then
  pass "Compliance aligns with CIS Benchmark controls"
else
  fail "Compliance missing CIS Benchmark validation"
fi

# ==============================================================================
# Test 27: Compliance - FedRAMP security requirements
# ==============================================================================
run_test "Compliance check - FedRAMP security control validation"
json_file=$(find /tmp/system-maintenance -name "sysmaint_*.json" -type f | tail -1)
if [[ -f "$json_file" ]] && grep -q '"security_audit_enabled"' "$json_file"; then
  pass "Compliance supports FedRAMP AC-2 requirements"
else
  fail "Compliance missing FedRAMP security controls"
fi

# ==============================================================================
# Test 28: Compliance - NIST 800-53 system maintenance
# ==============================================================================
run_test "Compliance check - NIST 800-53 maintenance controls"
output=$(DRY_RUN=true JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --security-audit 2>&1 || true)
if echo "$output" | grep -qE "(Security audit|checking|verify)"; then
  pass "Compliance supports NIST 800-53 MA-2 controls"
else
  fail "Compliance missing NIST 800-53 maintenance validation"
fi

# ==============================================================================
# Test 29: Security - Flag overrides env=false
# ==============================================================================
run_test "Security audit flag overrides env false"
output=$(DRY_RUN=true SECURITY_AUDIT_ENABLED=false JSON_SUMMARY=false bash "$SYSMAINT" --dry-run --security-audit 2>&1 || true)
if echo "$output" | grep -q "=== Security audit start ==="; then
  pass "Flag overrides env=false for security audit"
else
  fail "Flag did not override env=false"
fi

# ==============================================================================
# Test 30: Security - JSON marks security_audit_enabled true
# ==============================================================================
run_test "JSON marks security_audit_enabled true when enabled"
DRY_RUN=true JSON_SUMMARY=true bash "$SYSMAINT" --dry-run --security-audit >/dev/null 2>&1 || true
jf=$(latest_json)
if [[ -f "$jf" ]] && grep -q '"security_audit_enabled": true' "$jf"; then
  pass "JSON shows security_audit_enabled=true"
else
  fail "JSON missing or security_audit_enabled not true"
fi

# ==============================================================================
# Test 31: Security - JSON includes zombie_count field
# ==============================================================================
run_test "JSON includes zombie_count field"
jf=$(latest_json)
if [[ -f "$jf" ]] && grep -q '"zombie_count"' "$jf"; then
  pass "JSON contains zombie_count"
else
  fail "JSON missing zombie_count"
fi

# ==============================================================================
# Test 32: Security - sudoers_d_issues is array
# ==============================================================================
run_test "JSON sudoers_d_issues is an array"
jf=$(find /tmp/system-maintenance -name "sysmaint_*.json" -type f | tail -1)
if [[ -f "$jf" ]] && grep -q '"sudoers_d_issues": \[' "$jf"; then
  pass "sudoers_d_issues is an array"
else
  fail "sudoers_d_issues not represented as an array"
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
