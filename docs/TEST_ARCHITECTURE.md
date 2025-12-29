# SYSMAINT Test Architecture

**Version:** 1.0
**Last Updated:** 2025-12-28
**SPDX-License-Identifier:** MIT

## Table of Contents

1. [Overview](#overview)
2. [Test Structure](#test-structure)
3. [Test Framework](#test-framework)
4. [Test Categories](#test-categories)
5. [Execution Modes](#execution-modes)
6. [Result Collection](#result-collection)
7. [CI/CD Integration](#cicd-integration)

---

## Overview

The SYSMAINT test architecture is designed to provide comprehensive coverage across all supported Linux distributions while maintaining fast feedback and accurate result comparison.

### Design Principles

1. **Modular** - Each test suite is independent and reusable
2. **Consistent** - All tests follow the same structure and conventions
3. **Parallelizable** - Tests can run concurrently across OS
4. **Observable** - Test results are structured and comparable
5. **Automatable** - Full CI/CD integration with minimal manual steps

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                           SYSMAINT TEST ARCHITECTURE                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐    │
│  │ Local Docker │      │ GitHub       │      │ Cloud/VM     │    │
│  │ Testing      │◄────►│ Actions CI   │◄────►│ Testing       │    │
│  └──────────────┘      └──────────────┘      └──────────────┘    │
│         │                      │                      │            │
│         └──────────────────────┴──────────────────────┘            │
│                              │                                    │
│                              ▼                                    │
│                   ┌──────────────────┐                          │
│                   │ Result Collector│                          │
│                   │  (JSON Format)   │                          │
│                   └──────────────────┘                          │
│                              │                                    │
│                              ▼                                    │
│                   ┌──────────────────┐                          │
│                   │ Result Compare   │                          │
│                   │  (Analysis)      │                          │
│                   └──────────────────┘                          │
│                              │                                    │
│                              ▼                                    │
│                   ┌──────────────────┐                          │
│                   │  Reports        │                          │
│                   │  (Text/HTML/JSON)│                          │
│                   └──────────────────┘                          │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Test Structure

### Directory Layout

```
sysmaint/
├── tests/
│   ├── docker/                      # Docker infrastructure
│   │   ├── Dockerfile.ubuntu.test
│   │   ├── Dockerfile.debian.test
│   │   ├── Dockerfile.fedora.test
│   │   ├── Dockerfile.rhel.test
│   │   ├── Dockerfile.rocky.test
│   │   ├── Dockerfile.almalinux.test
│   │   ├── Dockerfile.centos.test
│   │   ├── Dockerfile.arch.test
│   │   ├── Dockerfile.opensuse.test
│   │   └── docker-compose.test.yml
│   │
│   ├── results/                     # Test results storage
│   │   ├── test_result_schema.json
│   │   ├── local-docker-*.json
│   │   ├── github-actions-*.json
│   │   └── discrepancies/
│   │
│   ├── test_suite_smoke.sh          # Basic functionality tests
│   ├── test_suite_*.sh              # Other test suites
│   │
│   ├── run_local_docker_tests.sh    # Local Docker runner
│   ├── quick_test.sh                # Quick validation
│   ├── full_test.sh                 # Full test suite
│   ├── test_single_os.sh            # Single OS tester
│   ├── validate_pr.sh               # Pre-PR validation
│   ├── run_dual_environment_tests.sh # Dual env orchestration
│   │
│   ├── collect_test_results.sh      # Result collector
│   ├── compare_test_results.py      # Comparison tool
│   ├── report_discrepancies.sh      # Discrepancy reporter
│   └── upload_test_results.sh       # GitHub upload
│
├── .github/workflows/
│   ├── test-matrix.yml              # Multi-OS test workflow
│   ├── ci.yml                       # Main CI workflow
│   └── docker.yml                   # Docker workflow
│
├── docs/
│   ├── TEST_MATRIX.md               # Test coverage matrix
│   ├── TEST_GUIDE.md                # Testing guide
│   ├── OS_SUPPORT.md                # OS compatibility
│   └── TEST_ARCHITECTURE.md         # This document
│
└── scripts/
    └── cleanup_workflows.sh         # CI cleanup utility
```

---

## Test Framework

### Standard Test Suite Template

All test suites follow this structure:

```bash
#!/bin/bash
#
# test_suite_<name>.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   Brief description of what this suite tests
#
# USAGE:
#   bash tests/test_suite_<name>.sh

set -e

# Test framework variables
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test framework functions
run_test() {
    local test_name="$1"
    local test_func="$2"

    ((TESTS_RUN++))
    log_test "$test_name"

    if $test_func; then
        ((TESTS_PASSED++))
        log_pass "$test_name"
        return 0
    else
        ((TESTS_FAILED++))
        log_fail "$test_name"
        return 1
    fi
}

# Test functions
test_example() {
    # Test implementation
    return 0  # 0 = pass, 1 = fail
}

# Main execution
main() {
    echo "========================================"
    echo "SYSMAINT <Test Suite Name>"
    echo "========================================"
    echo ""

    # Run tests
    run_test "Test name" test_example
    # ... more tests

    # Summary
    echo ""
    echo "========================================"
    echo "Test Summary"
    echo "========================================"
    echo "Tests run:    $TESTS_RUN"
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "All tests passed!"
        return 0
    else
        echo "Some tests failed!"
        return 1
    fi
}

main "$@"
```

### Logging Functions

```bash
log_test()    # Test start messages (GREEN)
log_pass()    # Pass messages (GREEN)
log_fail()    # Fail messages (RED)
log_info()    # Info messages (BLUE)
log_warning() # Warning messages (YELLOW)
```

---

## Test Categories

### 1. Smoke Tests (`test_suite_smoke.sh`)

**Purpose:** Fast basic functionality validation

**Tests:**
- SYSMAINT executable accessible
- Help command works
- Version command works
- OS detection works
- Basic command parsing

**Runtime:** ~10 seconds

### 2. OS Family Tests

| Suite | File | Target OS |
|-------|------|-----------|
| Debian Family | `test_suite_debian_family.sh` | Ubuntu, Debian |
| RedHat Family | `test_suite_redhat_family.sh` | RHEL, Rocky, Alma, CentOS |
| Arch Family | `test_suite_arch_family.sh` | Arch Linux |
| SUSE Family | `test_suite_suse_family.sh` | openSUSE |
| Fedora | `test_suite_fedora.sh` | Fedora |
| Cross-OS | `test_suite_cross_os_compatibility.sh` | All OS |

**Purpose:** Validate OS-specific behavior

**Tests:**
- Package manager detection
- Distribution-specific paths
- Release file verification
- Package manager operations

### 3. Mode Tests (`test_suite_modes.sh`)

**Purpose:** Validate execution modes

**Tests:**
- `--auto` mode
- `--gui` mode
- `--dry-run` mode
- `--quiet` mode
- `--verbose` mode
- `--json-summary` mode
- Mode combinations

### 4. Feature Tests (`test_suite_features.sh`)

**Purpose:** Validate specific features

**Tests:**
- Package management (`--upgrade`)
- System cleanup (`--cleanup`)
- Kernel purge (`--purge-kernels`)
- Security audit (`--security-audit`)
- Firmware updates (`--update-firmware`)
- Storage maintenance (fstrim, swap)

### 5. Security Tests (`test_suite_security.sh`)

**Purpose:** Security-focused validation

**Tests:**
- Permission checks
- File ownership
- GPG key validation
- SELinux/AppArmor status
- Firewall configuration

### 6. Performance Tests (`test_suite_performance.sh`)

**Purpose:** Performance benchmarking

**Tests:**
- Execution time
- Memory usage
- Package operations speed
- I/O performance

### 7. Edge Cases (`test_suite_edge.sh`, `test_suite_edge_cases.sh`)

**Purpose:** Failure scenario testing

**Tests:**
- Network failures
- Disk space issues
- Permission denied
- Package manager errors
- Interruption handling (SIGINT/SIGTERM)
- Corruption scenarios
- Concurrent execution
- Resource limits

### 8. Integration Tests (`test_suite_integration.sh`)

**Purpose:** System integration validation

**Tests:**
- Systemd timers and services
- Cron integration
- Docker environment
- Package installation
- Logging integration
- Service management
- Security integration
- Package managers
- Filesystem integration

### 9. Docker Tests (`test_suite_docker.sh`)

**Purpose:** Docker-specific testing

**Tests:**
- Docker environment and daemon
- Container execution
- Privileged mode
- Volume mounts
- Network isolation
- Dockerfile validation
- Multi-architecture support
- Docker Compose
- Container security
- Logging and orchestration

### 10. GitHub Actions Tests (`test_suite_github_actions.sh`)

**Purpose:** CI/CD environment testing

**Tests:**
- GitHub Actions environment variables
- Runner detection
- Workflow validation
- Matrix builds
- Artifacts and cache
- Secret management
- Checkout and permissions
- Service containers
- Test results handling
- Timeout and triggers

---

## Execution Modes

### Local Docker Mode

**Entry Point:** `run_local_docker_tests.sh`

**Flow:**
1. Build Docker images (if needed)
2. Run tests in containers
3. Collect results as JSON
4. Generate reports

**Example:**
```bash
./tests/run_local_docker_tests.sh --os ubuntu-24,debian-12 --parallel
```

### GitHub Actions Mode

**Entry Point:** `.github/workflows/test-matrix.yml`

**Flow:**
1. Triggered by push/PR/manual
2. Build test matrix (14 OS versions)
3. Run tests in parallel
4. Upload artifacts
5. Generate summary

### Dual Environment Mode

**Entry Point:** `run_dual_environment_tests.sh`

**Flow:**
1. Run local Docker tests
2. Trigger GitHub Actions
3. Wait for completion
4. Compare results
5. Generate discrepancy report

---

## Result Collection

### JSON Schema

All test results follow a unified JSON schema:

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
  "test_profile": "smoke",
  "results": {
    "suite_name": {
      "total": 10,
      "passed": 10,
      "failed": 0,
      "tests": [...]
    }
  },
  "summary": {
    "total": 10,
    "passed": 10,
    "failed": 0,
    "pass_rate": 100.0
  }
}
```

### Collection Process

```
┌─────────────────┐
│  Test Execution │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   STDOUT/STDERR │ (Log files)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Parser/Regex  │ (Extract counts)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  JSON Generator │ (Structure data)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  File Storage   │ (results/*.json)
└─────────────────┘
```

---

## CI/CD Integration

### GitHub Actions Workflow

**File:** `.github/workflows/test-matrix.yml`

**Matrix Configuration:**
```yaml
strategy:
  matrix:
    include:
      - os: ubuntu-22
        version: "22.04"
        image: ubuntu:22.04
      - os: ubuntu-24
        version: "24.04"
        image: ubuntu:24.04
      # ... all 14 OS versions
```

**Job Steps:**
1. Checkout code
2. Install dependencies
3. Setup test user
4. Copy SYSMAINT
5. Run test suite
6. Upload artifacts
7. Generate summary

### Result Comparison Workflow

```
┌──────────────┐
│ Local Docker │ ────┐
└──────────────┘     │
                      ├──► ┌─────────────┐
┌──────────────┐     │     │  Comparison │
│ GitHub Actions│ ────┘     │   Engine    │
└──────────────┘           └──────┬──────┘
                                 │
                                 ▼
                          ┌─────────────┐
                          │  Report     │
                          │  Generator  │
                          └─────────────┘
```

### Accuracy Metrics

| Metric | Description | Formula |
|--------|-------------|---------|
| **Pass Rate** | Tests passed / Total tests | `(passed/total)*100` |
| **Congruence** | Similarity between environments | `min(local,github)/max(local,github)*100` |
| **Accuracy Score** | Overall consistency | `(congruence + (100-count_diff))/2` |

---

## Test Dependencies

### Required Tools

All test environments must have:

```bash
# Core utilities
sudo, bash, coreutils, procps

# Test utilities
jq, shellcheck, curl, time

# Dialog (for GUI mode tests)
dialog

# Systemd (for service tests)
systemd
```

### Optional Tools

```bash
# Package managers (OS-specific)
apt, dnf, yum, pacman, zypper

# Container tools
docker, podman

# Firmware updates
fwupdmgr

# Alternative packaging
snap, flatpak
```

---

## Extending the Test Suite

### Adding a New Test Suite

1. Create `test_suite_<name>.sh`
2. Follow the standard template
3. Add test functions
4. Register in `run_all_tests.sh`
5. Update documentation

### Adding a New OS

1. Create `Dockerfile.<os>.test`
2. Add to `docker-compose.test.yml`
3. Update `run_local_docker_tests.sh`
4. Add to `test-matrix.yml`
5. Create OS-specific test suite
6. Update `OS_SUPPORT.md`

### Adding a New Test Category

1. Define category purpose
2. Create relevant test suites
3. Add to test documentation
4. Update CI matrix if needed

---

## Best Practices

### Test Design

1. **Keep tests independent** - Each test should work in isolation
2. **Use descriptive names** - Test names should clearly indicate what is tested
3. **Test one thing** - Each test function should validate one behavior
4. **Clean up after** - Remove temporary files and state
5. **Use timeouts** - Prevent tests from hanging

### Result Interpretation

1. **Check discrepancies** - Compare local vs CI results
2. **Investigate failures** - Use logs to understand why tests fail
3. **Validate fixes** - Re-run tests after changes
4. **Track trends** - Monitor test performance over time

---

## Troubleshooting

### Common Issues

**Docker tests fail:**
- Check Docker daemon status
- Verify privileged mode
- Ensure image exists

**GitHub Actions fail:**
- Check workflow syntax
- Verify container image availability
- Review runner logs

**Result comparison fails:**
- Verify JSON schema compliance
- Check file paths
- Validate environment detection

---

## References

- [Test Guide](TEST_GUIDE.md) - How to run tests
- [Test Summary](TEST_SUMMARY.md) - Complete test infrastructure overview
- [OS Support](OS_SUPPORT.md) - Supported distributions
- [Test Matrix](TEST_MATRIX.md) - Test coverage details
