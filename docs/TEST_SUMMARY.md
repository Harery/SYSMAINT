# SYSMAINT Test Infrastructure Summary

**Version:** 1.0
**Last Updated:** 2025-12-28
**SPDX-License-Identifier:** MIT

## Overview

This document provides a complete summary of the SYSMAINT test infrastructure, including all test suites, automation scripts, CI/CD workflows, and documentation.

---

## Quick Stats

| Metric | Count |
|--------|-------|
| **Total Test Suites** | 32 |
| **Total Test Cases** | 500+ |
| **Supported OS** | 9 distributions, 14 versions |
| **Package Managers** | 5 (apt, dnf/yum, pacman, zypper) |
| **CI/CD Environments** | 2 (Local Docker, GitHub Actions) |
| **Documentation Files** | 6 |
| **Automation Scripts** | 10+ |

---

## Test Suites Directory

```
tests/
├── test_suite_smoke.sh                    # Basic functionality (10+ tests)
├── test_suite_debian_family.sh            # Debian/Ubuntu tests
├── test_suite_redhat_family.sh            # RHEL/Rocky/Alma/CentOS tests
├── test_suite_arch_family.sh              # Arch Linux tests
├── test_suite_suse_family.sh              # openSUSE tests
├── test_suite_fedora.sh                   # Fedora 41 tests
├── test_suite_cross_os_compatibility.sh   # Cross-OS validation
├── test_suite_modes.sh                    # Execution mode tests
├── test_suite_features.sh                 # Feature-specific tests
├── test_suite_security.sh                 # Security-focused tests
├── test_suite_performance.sh              # Performance benchmarks
├── test_suite_edge_cases.sh               # Edge case and failure tests
├── test_suite_edge.sh                     # Additional edge cases
├── test_suite_integration.sh              # Integration tests
├── test_suite_docker.sh                   # Docker-specific tests (NEW)
├── test_suite_github_actions.sh           # CI/CD environment tests (NEW)
├── test_suite_functions.sh                # Function unit tests
├── test_suite_argument_matrix.sh          # Argument combinations
├── test_suite_combos.sh                   # Command combinations
├── test_suite_compliance.sh               # Compliance checks
├── test_suite_data_types.sh               # Data type handling
├── test_suite_docker_local.sh             # Local Docker tests
├── test_suite_environment.sh              # Environment tests
├── test_suite_error_handling.sh           # Error handling tests
├── test_suite_exit_codes.sh               # Exit code validation
├── test_suite_governance.sh               # Governance compliance
├── test_suite_gui_mode_extended.sh        # Extended GUI tests
├── test_suite_os_families.sh              # Multi-OS family tests
├── test_suite_parallel_execution.sh       # Parallel execution tests
├── test_suite_realmode_sandbox.sh         # Sandbox mode tests
├── test_suite_scanner_performance.sh      # Scanner performance
├── test_suite_scanners.sh                 # Scanner tests
└── test_suite_scanners.sh                 # Additional scanner tests
```

---

## Automation Scripts

### Test Runners

| Script | Purpose | Usage |
|--------|---------|-------|
| `run_all_tests.sh` | Master test runner | `bash tests/run_all_tests.sh --profile full` |
| `run_local_docker_tests.sh` | Local Docker testing | `bash tests/run_local_docker_tests.sh --os ubuntu-24` |
| `run_dual_environment_tests.sh` | Dual environment comparison | `bash tests/run_dual_environment_tests.sh --os ubuntu --version 24.04` |
| `quick_test.sh` | Quick smoke tests | `bash tests/quick_test.sh` |
| `full_test.sh` | Full test suite | `bash tests/full_test.sh --profile full` |
| `test_single_os.sh` | Single OS testing | `bash tests/test_single_os.sh ubuntu 24.04` |
| `validate_pr.sh` | PR validation | `bash tests/validate_pr.sh` |

### Result Management

| Script | Purpose | Usage |
|--------|---------|-------|
| `collect_test_results.sh` | Gather test results | `bash tests/collect_test_results.sh` |
| `compare_test_results.py` | Compare environments | `python3 tests/compare_test_results.py local.json github.json` |
| `report_discrepancies.sh` | Generate discrepancy report | `bash tests/report_discrepancies.sh --results tests/results` |
| `upload_test_results.sh` | Upload to GitHub | `bash tests/upload_test_results.sh --run-id 123` |

### Reporting

| Script | Purpose | Usage |
|--------|---------|-------|
| `generate_summary.sh` | Generate test summary | `bash tests/generate_summary.sh` |
| `generate_html_report.sh` | Generate HTML report | `bash tests/generate_html_report.sh --results tests/results` |
| `check_performance_regression.sh` | Performance regression check | `bash tests/check_performance_regression.sh --baseline tests/baseline.json` |

### Other Utilities

| Script | Purpose |
|--------|---------|
| `benchmarks.sh` | Run performance benchmarks |
| `cross_os_test_runner.sh` | Cross-OS test orchestration |
| `test_docker_detection.sh` | Docker environment detection |
| `test_gui_mode.sh` | GUI mode testing |
| `test_json_checksum.sh` | JSON checksum validation |
| `test_json_validation.sh` | JSON schema validation |
| `test_mock_failures.sh` | Mock failure scenarios |
| `test_package_build.sh` | Package build testing |
| `test_profile_ci.sh` | CI profile testing |

---

## CI/CD Workflows

### GitHub Actions

| Workflow | Triggers | Purpose |
|----------|----------|---------|
| `test-matrix.yml` | Push, PR, Manual | Multi-OS test matrix (14 OS versions) |
| `ci.yml` | Push, PR, Manual | Main CI pipeline with result collection |
| `docker.yml` | Push, Tags, Manual | Multi-variant Docker builds |
| `release.yml` | Tags | Release automation |

### Workflow Matrix

```yaml
# test-matrix.yml covers 14 OS versions:
- ubuntu: 22.04, 24.04
- debian: 12, 13
- fedora: 41
- rhel: 9, 10 (UBI)
- rocky: 9, 10
- almalinux: 9
- centos: stream 9
- arch: rolling
- opensuse: tumbleweed
```

---

## Test Result Schema

All test results follow the unified JSON schema:

```json
{
  "version": "1.0",
  "run_id": "unique-identifier",
  "timestamp": "ISO-8601",
  "environment": {
    "type": "local-docker|github-actions",
    "os_name": "ubuntu",
    "os_version": "24.04",
    "architecture": "x86_64"
  },
  "test_profile": "smoke|standard|full",
  "results": {
    "suite_name": {
      "total": 10,
      "passed": 10,
      "failed": 0,
      "tests": [...]
    }
  },
  "summary": {
    "total": 500,
    "passed": 495,
    "failed": 5,
    "pass_rate": 99.0
  }
}
```

---

## Test Execution Profiles

### Smoke Profile
**Duration:** ~10 seconds per OS
**Tests:** Basic functionality only
**Use Case:** Quick validation, PR checks

```bash
bash tests/run_all_tests.sh --profile smoke
```

**Includes:**
- test_suite_smoke.sh

### Standard Profile
**Duration:** ~5 minutes per OS
**Tests:** Core functionality validation
**Use Case:** Regular CI runs

```bash
bash tests/run_all_tests.sh --profile standard
```

**Includes:**
- test_suite_smoke.sh
- test_suite_debian_family.sh
- test_suite_redhat_family.sh
- test_suite_arch_family.sh
- test_suite_suse_family.sh
- test_suite_fedora.sh
- test_suite_cross_os_compatibility.sh
- test_suite_modes.sh
- test_suite_features.sh

### Full Profile
**Duration:** ~15 minutes per OS
**Tests:** All test suites
**Use Case:** Release validation

```bash
bash tests/run_all_tests.sh --profile full
```

**Includes:**
- All standard profile tests
- test_suite_security.sh
- test_suite_performance.sh
- test_suite_edge_cases.sh
- test_suite_integration.sh
- test_suite_docker.sh
- test_suite_github_actions.sh

---

## Accuracy Metrics

When comparing local Docker vs GitHub Actions results:

| Metric | Description | Formula |
|--------|-------------|---------|
| **Pass Rate** | Tests passed percentage | `(passed/total)*100` |
| **Congruence** | Environment similarity | `min(local,github)/max(local,github)*100` |
| **Accuracy Score** | Overall consistency | `(congruence + (100-count_diff))/2` |

---

## Documentation Files

| File | Description |
|------|-------------|
| `docs/TEST_GUIDE.md` | How to run tests locally |
| `docs/TEST_MATRIX.md` | Comprehensive test coverage (500+ tests) |
| `docs/TEST_ARCHITECTURE.md` | Test structure and design |
| `docs/OS_SUPPORT.md` | OS compatibility matrix |
| `docs/TEST_SUMMARY.md` | This file - infrastructure overview |

---

## Docker Test Infrastructure

### Dockerfiles

| File | Purpose |
|------|---------|
| `tests/docker/Dockerfile.ubuntu.test` | Ubuntu test environment |
| `tests/docker/Dockerfile.debian.test` | Debian test environment |
| `tests/docker/Dockerfile.fedora.test` | Fedora test environment |
| `tests/docker/Dockerfile.rhel.test` | RHEL test environment (UBI) |
| `tests/docker/Dockerfile.rocky.test` | Rocky Linux test environment |
| `tests/docker/Dockerfile.almalinux.test` | AlmaLinux test environment |
| `tests/docker/Dockerfile.centos.test` | CentOS Stream test environment |
| `tests/docker/Dockerfile.arch.test` | Arch Linux test environment |
| `tests/docker/Dockerfile.opensuse.test` | openSUSE test environment |

### Docker Compose

| File | Purpose |
|------|---------|
| `tests/docker/docker-compose.test.yml` | Multi-container test orchestration |

---

## Getting Started

### 1. Quick Local Test

```bash
cd /path/to/sysmaint
bash tests/quick_test.sh
```

### 2. Test Specific OS in Docker

```bash
bash tests/test_single_os.sh ubuntu 24.04
```

### 3. Full Test Suite (Local Docker)

```bash
bash tests/full_test.sh --profile full --parallel
```

### 4. Run Specific Test Suite

```bash
bash tests/test_suite_smoke.sh
bash tests/test_suite_debian_family.sh
bash tests/test_suite_docker.sh
```

### 5. Compare Local vs CI Results

```bash
# Run local tests
bash tests/run_local_docker_tests.sh --os ubuntu-24

# Trigger GitHub Actions
gh workflow run test-matrix.yml -f test_profile=full -f os_filter=ubuntu-24

# Compare results
bash tests/run_dual_environment_tests.sh --os ubuntu --version 24.04
```

---

## Troubleshooting

### Docker Tests Fail

```bash
# Check Docker daemon
docker info

# Verify privileged mode
docker run --rm --privileged alpine:latest uptime

# Rebuild images
docker rmi sysmaint-test:*
bash tests/run_local_docker_tests.sh --rebuild
```

### GitHub Actions Fail

```bash
# Check workflow syntax
yamllint .github/workflows/test-matrix.yml

# Trigger manual run
gh workflow run test-matrix.yml

# View run logs
gh run watch
```

### Test Result Collection Fails

```bash
# Verify jq is installed
jq --version

# Check results directory
ls -la tests/results/

# Manually collect results
bash tests/collect_test_results.sh --verbose
```

---

## Contributing

When adding new tests:

1. Follow the standard test suite template
2. Add tests to `TEST_MATRIX.md`
3. Update suite counts in documentation
4. Add to appropriate profile in `run_all_tests.sh`
5. Update `README.md` if significant

---

## References

- [Main README](../README.md)
- [Test Guide](TEST_GUIDE.md)
- [Test Matrix](TEST_MATRIX.md)
- [Test Architecture](TEST_ARCHITECTURE.md)
- [OS Support](OS_SUPPORT.md)

---

**Maintained by:** @Harery
**Last Review:** 2025-12-28
**Status:** ✅ Complete
