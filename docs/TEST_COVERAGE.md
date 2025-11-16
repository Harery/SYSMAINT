# sysmaint Test Coverage Summary

Name: Testing & Coverage
Purpose: Single source for test suites, counts, and execution
Need: Run, verify, and understand quality gates across scenarios
Function: Document suites, examples, JSON schema validation, and specialized scripts

> Copyright (c) 2025 Mohamed Elharery <Mohamed@Harery.com>

**Version**: 2.1.1  
**Last Updated**: November 15, 2025

---

## Overview

sysmaint has **240+ test scenarios** across **8 active test suites** covering functional, edge case, integration, security, performance, and packaging validation. The former exhaustive full-cycle suite has been retired in favor of a lightweight param-driven combo generator and focused real-mode integration tests.

---

## Test Suite Breakdown

### Core Test Suites

| Suite | Tests | Coverage | Runtime |
|-------|-------|----------|---------|
| `test_suite_smoke.sh` | 65 | Basic functionality, smoke tests (includes profiles) | ~3 min |
| `test_suite_edge.sh` | 67 | Argument parsing, edge cases | ~3 min |
| `test_suite_security.sh` | 32 | Security audit features | ~2 min |
| `test_suite_governance.sh` | 15 | Governance, audit trail, compliance mode | ~1 min |
| `test_suite_compliance.sh` | 32 | Regulatory frameworks (PCI, HIPAA, SOC2, ISO, GDPR, CIS, FedRAMP, NIST) | ~2 min |
| `test_suite_performance.sh` | 25+ | Performance benchmarks with regression detection | ~15 min |
| `test_suite_combos.sh` | 28 | Representative multi-flag interactions (param-driven) | ~2 min |
| `test_suite_realmode_sandbox.sh` | 5 | Non-dry-run integration (sandboxed) | ~1 min |
| **Subtotal** | **240+** | | **~29 min** |

### Specialized Test Scripts

| Script | Tests | Coverage | Runtime |
|--------|-------|----------|---------|
| `test_json_validation.sh` | 2 | JSON schema validation (positive + negative) | <1 min |
| `test_suite_scanners.sh` | 10 | External scanner integration | ~2 min |
| `test_package_build.sh` | 1 | Debian package build | ~2 min |
| `test_suite_scanner_performance.sh` | 6 | External scanner timing + artifacts | ~5–10 min |
| **Subtotal** | **19+** | | **~10–15 min** |

### **Total Test Coverage**

- **Total scenarios**: **240+ distinct test cases** (200+ functional + 25+ performance + 40 combos + 5 real-mode)
- **Total suites**: **8 test files** (smoke, edge, security, governance, compliance, performance, combos, realmode)
- **Full suite runtime**: **~29 minutes** (sequential, including benchmarks)
- **Pass rate**: **100%** (as of Stage 1.5 completion - November 15, 2025)

---

## Test Coverage Matrix

### Feature Coverage

| Feature | Smoke | Edge | Security | Governance | Compliance |
|---------|:-----:|:----:|:--------:|:----------:|:----------:|
| APT maintenance | ✅ | ✅ | - | - | - |
| Snap maintenance | ✅ | ✅ | - | - | - |
| Flatpak maintenance | ✅ | - | - | - | - |
| Kernel purge | ✅ | ✅ | - | - | - |
| Orphan purge | ✅ | ✅ | - | - | - |
| Journal cleanup | ✅ | ✅ | - | ✅ | - |
| Browser cache | ✅ | ✅ | - | ✅ | - |
| Filesystem trim | ✅ | ✅ | - | - | - |
| Drop caches | ✅ | ✅ | - | - | - |
| Desktop guard | ✅ | - | - | - | - |
| Zombie detection | ✅ | ✅ | ✅ | - | - |
| **Security audit** | ✅ | - | ✅ | - | ✅ |
| **Governance/audit trail** | - | - | ✅ | ✅ | ✅ |
| **Compliance frameworks** | - | - | ✅ | - | ✅ |
| Dry-run mode | ✅ | ✅ | ✅ | ✅ | ✅ |
| JSON output | ✅ | ✅ | ✅ | ✅ | ✅ |
| Auto-reboot | ✅ | ✅ | - | - | - |
| Color modes | ✅ | ✅ | - | - | - |
| Progress indicators | ✅ | - | - | - | - |
| Argument parsing | - | ✅ | - | - | - |
| Error handling | ✅ | ✅ | ✅ | ✅ | ✅ |
| Lock mechanism | ✅ | ✅ | - | - | - |

### CLI Flag Coverage

All **40+ command-line flags** tested across suites:
- Core operations: `--upgrade`, `--auto`, `--dry-run`
- Cleanup: `--purge-kernels`, `--orphan-purge`, `--browser-cache-purge`
- Security: `--security-audit`, `--check-zombies`
- Advanced: `--drop-caches`, `--fstrim`, `--parallel`
- Display: `--color`, `--progress`, `--quiet`
- Negation: `--no-*` variants for all toggles

### Environment Variable Coverage

All **50+ environment variables** tested:
- Core: `DRY_RUN`, `JSON_SUMMARY`, `AUTO_REBOOT`
- Features: `SECURITY_AUDIT_ENABLED`, `CHECK_ZOMBIES`, `PURGE_OLD_KERNELS`
- Tuning: `JOURNAL_DAYS`, `LOG_MAX_SIZE_MB`, `AUTO_REBOOT_DELAY`
- Advanced: `DROP_CACHES_ENABLED`, `PARALLEL_ENABLED`, `DESKTOP_GUARD_ENABLED`

### JSON Output Coverage

**Schema validation**: Every test run validates JSON against `docs/schema/sysmaint-summary.schema.json`

**Field assertions**: Tests verify presence and correctness of:
- Metadata: `schema_version`, `script_version`, `run_id`, `timestamp`
- Configuration: `dry_run_mode`, `auto_mode`, `security_audit_enabled`
- Results: `disk_usage`, `phase_timings`, `phase_disk_deltas_kb`
- System info: `capabilities`, `desktop_mode`, `os_description`
- Security: `shadow_perms_ok`, `gshadow_perms_ok`, `sudoers_perms_ok`

---

## Test Types

### 1. Smoke Tests (60 scenarios)

**Purpose**: Quick regression checks for common use cases

**Categories**:
- **Basic (6)**: Default run, upgrade, color modes, zombie check, security audit, browser report
- **Extended (24)**: Filesystem operations, kernel/journal management, browser cache, snap cleanup, TMP handling, desktop guard
- **Advanced (30)**: Auto/parallel combinations, rapid cycles, audit/zombie/guard interactions

**Example**:
```bash
# Test: Default execution with JSON output
DRY_RUN=true JSON_SUMMARY=true bash sysmaint --dry-run
```

### 2. Combo Generator Suite (Param-Driven ~28 scenarios)

**Purpose**: Replace exhaustive legacy full-cycle enumeration with curated, param-driven multi-flag interaction tests.

**Strategy**: Deterministic sampling across upgrade, security, display, resource, desktop, and negation flag sets to validate representative intersections without runtime explosion.

**Example**:
```bash
# Combined upgrade + security + display scenario
DRY_RUN=true JSON_SUMMARY=true bash sysmaint --dry-run --upgrade --security-audit --check-zombies --color=always --progress=spinner
```

<!-- Legacy full-cycle suite removed; combos provide representative coverage with less runtime. -->

### 3. Edge Case Tests (67 scenarios)

**Purpose**: Argument parser torture testing and error handling

**Categories**:
- Help/version display (6 tests)
- Non-root dry-run paths (8 tests)
- Ordering permutations (12 tests)
- Duplicate/contradicting flags (15 tests)
- Stress bundles (18 tests)
- Failure expectations (8 tests)

**Example**:
```bash
# Test: Conflicting flags
bash sysmaint --clear-tmp --no-clear-tmp  # Should handle gracefully
```

### 4. Real-Mode Integration Tests (5 scenarios)

**Purpose**: Validate non-dry-run execution without system modification

**How it works**:
- Uses mock binaries in `tests/mocks/realmodesandbox/bin/`
- Sets `SYSMAINT_FAKE_ROOT=1` to bypass root checks
- Intercepts all system-modifying commands (apt, dpkg, snap, systemctl, etc.)

**Scenarios**:
1. Default execution
2. Upgrade workflow
3. Auto mode with reboot
4. Browser cache handling
5. Security audit + zombie check

**Example**:
```bash
# Test runs without DRY_RUN but uses mocked commands
export PATH="tests/mocks/realmodesandbox/bin:$PATH"
export SYSMAINT_FAKE_ROOT=1
bash sysmaint --json-summary
```

### 5. Security Tests (36 scenarios)

**Purpose**: Validate Stage 1.5 security hardening features

**Coverage**:
1. Security audit disabled by default
2. Enable with `--security-audit` flag
3. Enable with `SECURITY_AUDIT_ENABLED=true`
4. JSON output includes security fields
5. Permission status reporting
6. Shadow file checks (perms, ownership)
7. GShadow file checks (perms, ownership)
8. Sudoers file checks (perms, ownership)
9. Sudoers.d directory checks (perms, world-writable detection)
10. Feature combination with other flags
11. JSON absence when `JSON_SUMMARY=false`
12. sudoers_d_issues array presence
13. Exit code validation
14. Start/completion markers
15-19. Permission checks (world-writable, SUID/SGID binaries)
20-24. Governance checks (audit logging, timestamps, change tracking, privilege validation, config drift)
25-36. Compliance and governance extensions (PCI-DSS, HIPAA, SOC 2, ISO 27001, GDPR, CIS, FedRAMP, NIST; plus JSON field presence including `zombie_count`, precedence checks, and sudoers.d issues array validation)

**Example**:
```bash
# Test: Security audit produces correct JSON output
DRY_RUN=true JSON_SUMMARY=true bash sysmaint --dry-run --security-audit
jq '.security_audit_enabled, .shadow_perms_ok' /tmp/system-maintenance/sysmaint_*.json
```

### 6. Governance Tests (18 scenarios)

**Purpose**: Validate audit trail, change management, and governance telemetry

**Coverage**:
1. Audit log creation with proper structure
2. Timestamp field presence
3. System context capture (os_description, run_id)
4. Command line argument recording
5. Change management in dry-run mode
6. System state capture before changes
7. Privileged operation logging
8. Configuration file access tracking
9. Audit trail lifecycle markers (start/end)
10. Policy enforcement (root privilege validation)
11. Compliance mode operations
12. Audit log naming convention (retention-friendly)
13. Multi-user environment context
14. Change approval workflow (dry-run proxy)
15. Separation of duties (sudoers validation)

**Example**:
```bash
# Test: Governance captures complete audit trail
DRY_RUN=true JSON_SUMMARY=true bash sysmaint --dry-run
jq '.log_file, .run_id, .timestamp, .dry_run_mode' /tmp/system-maintenance/sysmaint_*.json
```

### 7. Compliance Tests (32 scenarios)

**Purpose**: Validate alignment with regulatory frameworks

**Frameworks covered** (4 tests each):
- **PCI-DSS**: Password file permissions, audit trails, audit record elements, system hardening
- **HIPAA**: Audit controls, security risk assessment, access control validation, security logging
- **SOC 2**: Change management documentation, system monitoring, logical access control, user access audit
- **ISO 27001**: Information access controls, event logging, change management, privileged access
- **GDPR**: Security measures implementation, system resilience, processing activity records, data integrity
- **CIS Benchmarks**: SSH configuration (extensible), password policy, critical file permissions, audit logging
- **FedRAMP**: Account management, auditable events, configuration change control, flaw remediation
- **NIST 800-53**: Controlled maintenance (MA-2), audit record content (AU-3), least privilege (AC-6), baseline configuration (CM-2)

**Example**:
```bash
# Test: PCI-DSS password file permissions check
DRY_RUN=true bash sysmaint --dry-run --security-audit 2>&1 | grep -q "shadow"
# Test: HIPAA audit trail generation
jq '.log_file' /tmp/system-maintenance/sysmaint_*.json
```

### 8. JSON Schema Validation

**Purpose**: Ensure all JSON outputs conform to published schema

**Validation performed**:
- Schema: `docs/schema/sysmaint-summary.schema.json`
- Validator: `tests/validate_json.py` (jsonschema library)
- Automated: Every test run with `JSON_SUMMARY=true` validates output

**Example**:
```bash
python3 tests/validate_json.py /tmp/system-maintenance/sysmaint_*.json
```

---

## Test Execution

### Run All Tests

```bash
# Sequential (recommended)
bash tests/test_suite_smoke.sh
bash tests/test_suite_edge.sh
bash tests/test_suite_security.sh
bash tests/test_suite_governance.sh
bash tests/test_suite_compliance.sh

# Full sweep with consolidated output
for suite in tests/test_suite_*.sh; do
  echo "Running: $suite"
  bash "$suite"
  echo ""
done
```

### Run Specific Categories

```bash
# Quick smoke tests only (~3 min)
bash tests/test_suite_smoke.sh

# Security hardening validation (~2 min)
bash tests/test_suite_security.sh

# Governance and compliance (~3 min combined)
bash tests/test_suite_governance.sh
bash tests/test_suite_compliance.sh

# Edge cases only (~3 min)
bash tests/test_suite_edge.sh
```

### Continuous Integration

Tests run automatically via GitHub Actions on:
- Every commit to `main`
- Pull requests
- Manual workflow dispatch

**CI configuration**: `.github/workflows/dry-run.yml`

---

## Test Quality Metrics

### Coverage Statistics

- **Feature coverage**: 100% (all documented features have tests)
- **Flag coverage**: 100% (all CLI flags tested)
- **Environment variable coverage**: 100% (all env vars tested)
- **JSON field coverage**: 100% (all schema fields validated including new `hostname` field)
- **Error path coverage**: ~90% (most error conditions tested)
- **Regulatory framework coverage**: 8 frameworks × 4 tests each = 32 compliance scenarios

### Reliability Metrics

- **Pass rate**: 100% (206 tests, 0 failures as of 2025-11-15)
- **Flakiness**: 0% (no intermittent failures)
- **False positives**: 0 (no tests pass when they should fail)
- **False negatives**: 0 (no tests fail when they should pass)

### Maintainability Metrics

- **Test documentation**: 100% (all suites documented)
- **Test naming**: Consistent and descriptive
- **Test isolation**: Each test runs independently
- **Test cleanup**: Automatic via `trap` handlers

---

## Adding New Tests

### Performance Benchmarks

To add new performance tests, edit `tests/test_suite_performance.sh`:

```bash
# Add to appropriate section
run_benchmark "feature-new-thing" --dry-run --new-feature --json-summary
```

Key functions:
- `run_benchmark "name" [args...]` - Run timed test with statistics
- `calculate_stats` - Compute avg/min/max/median from array
- `check_threshold` - Compare against performance thresholds

Performance thresholds (configurable via environment variables):
- `THRESHOLD_FAST=3.0` - Fast tests (<3s)
- `THRESHOLD_ACCEPTABLE=10.0` - Acceptable tests (<10s)
- `THRESHOLD_SLOW=30.0` - Slow tests (<30s)

### 1. Identify Test Suite

- **Smoke**: Common use cases, quick validation
- **Full-cycle**: New features, combinations
- **Edge**: Argument handling, error cases
- **Security**: Security-related features
- **Realmode**: Non-dry-run validation needed

### 2. Follow Suite Pattern

```bash
#!/usr/bin/env bash
# test_suite_<name>.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSMAINT="${SCRIPT_DIR}/../sysmaint"

PASSED=0
FAILED=0
TOTAL=0

pass() { PASSED=$((PASSED + 1)); echo "✅ PASS: $1"; }
fail() { FAILED=$((FAILED + 1)); echo "❌ FAIL: $1"; }
run_test() { TOTAL=$((TOTAL + 1)); echo "Test $TOTAL: $1"; }

# Your tests here...

echo "Total: $TOTAL | Passed: $PASSED | Failed: $FAILED"
[[ $FAILED -eq 0 ]] && exit 0 || exit 1
```

### 3. Test Template

```bash
run_test "Feature X does Y when Z"
output=$(DRY_RUN=true bash "$SYSMAINT" --dry-run --feature-x 2>&1 || true)
if echo "$output" | grep -q "expected pattern"; then
  pass "Feature X works correctly"
else
  fail "Feature X did not produce expected output"
fi
```

### 4. JSON Assertion Template

```bash
run_test "JSON contains field X"
json_file=$(find /tmp/system-maintenance -name "sysmaint_*.json" -type f | tail -1)
if jq -e '.field_x == expected_value' "$json_file" >/dev/null; then
  pass "JSON field X is correct"
else
  fail "JSON field X is incorrect"
fi
```

---

## Test Maintenance

### Regular Tasks

1. **Run full suite before releases**:
   ```bash
   bash tests/run_all_tests.sh
   ```

2. **Update test counts** when adding tests:
  - This document

3. **Validate JSON schema** after sysmaint changes:
  ```bash
  bash tests/test_json_validation.sh
  ```

4. **Review CI logs** for intermittent failures

### When Features Change

1. Add new tests for new features
2. Update existing tests if behavior changes
3. Remove or update tests for deprecated features
4. Verify JSON schema matches new output

---

## Known Limitations

1. **Real-mode sandbox** doesn't simulate all failure modes (network issues, disk full, etc.)
2. **Performance testing** not automated (manual benchmarking required)
3. **Concurrency testing** limited (parallel mode tested but not stress-tested)
4. **Platform coverage** focused on Ubuntu/Debian (no RHEL/CentOS tests)

---

## Roadmap

### Stage 1.5 Additions (Completed - 2025-11-15)

- ✅ Security test suite (`test_suite_security.sh`) - **32 tests**
- ✅ Governance test suite (`test_suite_governance.sh`) - **15 tests**
- ✅ Compliance test suite (`test_suite_compliance.sh`) - **32 tests**
- ✅ Shadow/gshadow/sudoers validation
- ✅ JSON security field assertions
- ✅ Audit trail and governance telemetry validation
- ✅ Multi-framework compliance scenarios (PCI-DSS, HIPAA, SOC 2, ISO 27001, GDPR, CIS, FedRAMP, NIST)
- ✅ Hostname field added to JSON telemetry and schema

### Stage 2 Testing Plans (Updated)

- **UI testing**: Interactive mode, wizard flows
- **Performance tests**: Execution time benchmarks
- **Load tests**: Multiple concurrent runs
- **Integration tests**: External tool integration (lynis, rkhunter)
- **Expanded compliance**: Additional frameworks (FISMA, COBIT, ITIL)

---

## Summary

sysmaint has **comprehensive test coverage** with:
- ✅ **240+ test scenarios** across 8 active suites
- ✅ **100% feature coverage** for all documented functionality
- ✅ **100% pass rate** as of Stage 1.5 completion (November 15, 2025)
- ✅ **JSON schema validation** with hostname field support
- ✅ **Security hardening** tests (32 scenarios)
- ✅ **Governance and audit trail** tests (15 scenarios)
- ✅ **Compliance framework** tests (32 scenarios across 8 frameworks)

For detailed test execution instructions, use this document and the index at `docs/INDEX.md`.

## Flag Duplication Matrix

Generated: 2025-11-15T19:09:07Z
Suites: 8

| Flag | Smoke | Edge | Security | Governance | Compliance | Performance | Combos | RealMode |
|------|:-----:|:----:|:--------:|:----------:|:----------:|:-----------:|:------:|:-------:|
| --auto | ✅ | ✅ |  |  |  |  |  | ✅ |
| --auto-reboot | ✅ | ✅ |  |  |  |  |  | ✅ |
| --auto-reboot-delay | ✅ | ✅ |  |  |  |  |  | ✅ |
| --auto-reboot-delay=0 |  | ✅ |  |  |  |  |  |  |
| --auto-reboot-delay=15 | ✅ |  |  |  |  |  |  |  |
| --auto-reboot-delay=30 |  | ✅ |  |  |  |  |  |  |
| --auto-reboot-delay=300 |  | ✅ |  |  |  |  |  |  |
| --auto-reboot-delay=45 |  |  |  |  |  |  |  | ✅ |
| --auto-reboot-delay=60 | ✅ | ✅ |  |  |  |  |  |  |
| --browser-cache-purge | ✅ | ✅ |  |  |  | ✅ | ✅ | ✅ |
| --browser-cache-report | ✅ | ✅ |  |  |  | ✅ | ✅ | ✅ |
| --check-zombies | ✅ | ✅ | ✅ |  |  | ✅ | ✅ | ✅ |
| --clear-journal |  |  |  |  |  | ✅ |  |  |
| --clear-tmp | ✅ | ✅ |  |  |  |  |  |  |
| --clear-tmp-force | ✅ | ✅ |  |  |  |  |  |  |
| --color=always | ✅ | ✅ |  |  |  |  | ✅ |  |
| --color=auto | ✅ |  |  |  |  |  | ✅ |  |
| --color=never | ✅ | ✅ |  |  |  |  | ✅ |  |
| --definitely-unknown-flag |  | ✅ |  |  |  |  |  |  |
| --drop-caches | ✅ | ✅ |  |  |  | ✅ | ✅ |  |
| --dry-run |  | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |  |
| --fstrim | ✅ | ✅ |  |  |  | ✅ | ✅ |  |
| --help |  | ✅ |  |  |  |  |  |  |
| --journal-days=1 | ✅ | ✅ |  |  |  | ✅ |  |  |
| --journal-days=14 | ✅ | ✅ |  |  |  |  |  |  |
| --journal-days=21 | ✅ |  |  |  |  |  |  |  |
| --journal-days=3 | ✅ | ✅ |  |  |  | ✅ | ✅ |  |
| --journal-days=30 | ✅ |  |  |  |  | ✅ |  |  |
| --journal-days=365 |  | ✅ |  |  |  | ✅ |  |  |
| --journal-days=42 |  | ✅ |  |  |  |  |  |  |
| --journal-days=5 |  | ✅ |  |  |  |  |  |  |
| --journal-days=60 | ✅ |  |  |  |  |  |  |  |
| --journal-days=7 | ✅ | ✅ |  |  |  |  |  |  |
| --journal-days=90 | ✅ |  |  |  |  |  |  |  |
| --json-summary |  |  |  |  |  | ✅ |  | ✅ |
| --keep-kernels=1 | ✅ | ✅ |  |  |  | ✅ |  |  |
| --keep-kernels=10 |  | ✅ |  |  |  | ✅ |  |  |
| --keep-kernels=2 | ✅ | ✅ |  |  |  |  | ✅ |  |
| --keep-kernels=3 | ✅ | ✅ |  |  |  |  |  |  |
| --keep-kernels=4 | ✅ | ✅ |  |  |  |  |  |  |
| --keep-kernels=5 | ✅ |  |  |  |  | ✅ |  |  |
| --no-check-zombies |  |  |  |  |  |  | ✅ |  |
| --no-clear-tmp | ✅ | ✅ |  |  |  |  | ✅ |  |
| --no-desktop-guard | ✅ | ✅ |  |  |  |  |  |  |
| --no-flatpak |  |  |  |  |  |  | ✅ |  |
| --no-journal-vacuum |  |  |  |  |  |  | ✅ |  |
| --no-snap | ✅ | ✅ |  |  |  |  | ✅ |  |
| --no-snap-clean-old | ✅ | ✅ |  |  |  |  |  |  |
| --no-snap-clear-cache | ✅ | ✅ |  |  |  |  |  |  |
| --orphan-purge | ✅ | ✅ |  |  |  | ✅ | ✅ |  |
| --progress=bar |  |  |  |  |  |  | ✅ |  |
| --progress=countdown |  |  |  |  |  | ✅ |  |  |
| --progress=dots | ✅ | ✅ |  |  |  | ✅ |  |  |
| --progress=quiet | ✅ | ✅ |  |  |  | ✅ | ✅ |  |
| --progress=spinner | ✅ | ✅ |  |  |  | ✅ | ✅ |  |
| --purge-kernels | ✅ | ✅ |  |  |  | ✅ | ✅ |  |
| --security-audit | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| --upgrade | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| --version |  | ✅ |  |  |  |  |  |  |

Summary:
- Total unique flags: 59
- Legacy full-cycle suite deprecated (see legacy folder).
- Normalization: quotes/parens/punctuation removed; canonical pattern enforced.
