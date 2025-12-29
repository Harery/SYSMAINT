# SYSMAINT Test Guide

**Version:** 1.0
**Last Updated:** 2025-12-28
**SPDX-License-Identifier:** MIT

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Test Environments](#test-environments)
4. [Running Tests Locally](#running-tests-locally)
5. [Running Tests in Docker](#running-tests-in-docker)
6. [GitHub Actions Testing](#github-actions-testing)
7. [Test Result Comparison](#test-result-comparison)
8. [Troubleshooting](#troubleshooting)

---

## Overview

SYSMAINT provides comprehensive testing infrastructure supporting:
- **9 Linux distributions** across 14 versions
- **Local Docker testing** for fast feedback
- **GitHub Actions CI/CD** for continuous integration
- **Result comparison** to identify discrepancies

### Test Categories

| Category | Description | Scripts |
|----------|-------------|---------|
| **Smoke Tests** | Fast basic functionality | `test_suite_smoke.sh` |
| **OS Family Tests** | Distribution-specific | `test_suite_*_family.sh` |
| **Mode Tests** | Execution modes | `test_suite_modes.sh` |
| **Feature Tests** | Specific features | `test_suite_features.sh` |
| **Security Tests** | Security validations | `test_suite_security.sh` |
| **Performance Tests** | Benchmarks | `test_suite_performance.sh` |
| **Edge Cases** | Failure scenarios | `test_suite_edge.sh`, `test_suite_edge_cases.sh` |
| **Integration** | System integration | `test_suite_integration.sh` |
| **Docker** | Container-specific | `test_suite_docker.sh` |
| **GitHub Actions** | CI/CD environment | `test_suite_github_actions.sh` |

> **Full Infrastructure Overview:** See [TEST_SUMMARY.md](TEST_SUMMARY.md) for complete test infrastructure documentation.

---

## Quick Start

### Run Quick Tests (Current System)

```bash
# Fast smoke tests
./tests/quick_test.sh

# Or directly
cd tests && bash test_suite_smoke.sh
```

### Run Tests for Specific OS (Docker)

```bash
# Test Ubuntu 24.04
./tests/test_single_os.sh ubuntu 24.04

# Test Debian 12
./tests/test_single_os.sh debian 12

# Test Fedora 41
./tests/test_single_os.sh fedora 41
```

### Validate Before PR

```bash
# Run PR validation
./tests/validate_pr.sh
```

---

## Test Environments

### Local Docker Testing

Run tests in isolated Docker containers matching production environments.

**Supported OS:**
| Family | Distributions |
|--------|---------------|
| Debian | Ubuntu 22.04, 24.04, Debian 12, 13 |
| RedHat | RHEL 9, 10, Rocky 9, 10, AlmaLinux 9, CentOS Stream 9 |
| Fedora | Fedora 41 |
| Arch | Arch Linux (rolling) |
| SUSE | openSUSE Tumbleweed |

### GitHub Actions Testing

Automated testing runs on:
- Push to `main` or `develop` branches
- Pull requests
- Manual workflow dispatch

---

## Running Tests Locally

### Method 1: Quick Test Script

```bash
./tests/quick_test.sh
```

**Options:**
- `--os OS` - Target OS (default: auto-detect)
- `--local-only` - Skip GitHub Actions
- `--github-only` - Only trigger CI
- `--skip-compare` - Skip result comparison

### Method 2: Single OS Tester

```bash
./tests/test_single_os.sh OS [VERSION]
```

**Examples:**
```bash
# Ubuntu with default version (24.04)
./tests/test_single_os.sh ubuntu

# Specific version
./tests/test_single_os.sh debian 13

# Arch Linux
./tests/test_single_os.sh arch
```

### Method 3: Full Test Suite

```bash
# Quick smoke tests on default OS
./tests/full_test.sh

# Full tests on specific OS
./tests/full_test.sh --os ubuntu-24,debian-12

# Parallel execution
./tests/full_test.sh --parallel --os ubuntu-24,debian-12,fedora-41

# Security tests
./tests/full_test.sh --profile security
```

**Profiles:**
- `smoke` - Fast smoke tests (default)
- `full` - All scenarios on all OS
- `security` - Security-focused tests
- `performance` - Performance benchmarks
- `os_families` - One from each family

### Method 4: Direct Test Suite Execution

```bash
cd tests

# Run specific test suite
bash test_suite_smoke.sh
bash test_suite_debian_family.sh
bash test_suite_modes.sh
bash test_suite_features.sh
bash test_suite_security.sh
```

---

## Running Tests in Docker

### Using Docker Compose

```bash
# Build and run all test containers
docker-compose -f tests/docker/docker-compose.test.yml build
docker-compose -f tests/docker/docker-compose.test.yml up

# Run specific OS
docker-compose -f tests/docker/docker-compose.test.yml up ubuntu-24

# Run in background
docker-compose -f tests/docker/docker-compose.test.yml up -d
```

### Using Test Runner Script

```bash
# Single OS
./tests/run_local_docker_tests.sh --os ubuntu-24

# Multiple OS (sequential)
./tests/run_local_docker_tests.sh --os ubuntu-24,debian-12,fedora-41

# Multiple OS (parallel)
./tests/run_local_docker_tests.sh --os ubuntu-24,debian-12 --parallel

# Rebuild images first
./tests/run_local_docker_tests.sh --os ubuntu-24 --build
```

**Options:**
- `--os LIST` - Comma-separated OS list
- `--profile NAME` - Test profile
- `--parallel` - Run in parallel
- `--build` - Rebuild images
- `--dry-run` - Show what would run

### Building Individual Docker Images

```bash
# Ubuntu
docker build -f tests/docker/Dockerfile.ubuntu.test \
    --build-arg BASE_IMAGE=ubuntu:24.04 \
    -t sysmaint-test:ubuntu-24.04 .

# Debian
docker build -f tests/docker/Dockerfile.debian.test \
    --build-arg BASE_IMAGE=debian:12 \
    -t sysmaint-test:debian-12 .

# Fedora
docker build -f tests/docker/Dockerfile.fedora.test \
    --build-arg BASE_IMAGE=fedora:41 \
    -t sysmaint-test:fedora-41 .
```

---

## GitHub Actions Testing

### Triggering Tests

**Automatic:**
- Push to `main` or `develop`
- Create/update pull request

**Manual:**
```bash
# Using GitHub CLI
gh workflow run test-matrix.yml \
    -f test_profile=smoke \
    -f os_filter=ubuntu-24

# Watch the run
gh run watch

# View recent runs
gh run list --workflow=test-matrix.yml
```

### Test Matrix

The GitHub Actions workflow tests:
- All 14 OS versions in parallel
- Smoke tests by default
- Security, performance, and full profiles available

### Downloading Test Results

```bash
# Download artifacts from latest run
gh run download --name test-results-ubuntu-24

# Download from specific run
gh run download <run-id> -D results/
```

---

## Test Result Comparison

Compare results between local Docker and GitHub Actions to identify discrepancies.

### Collect Results

```bash
# Collect local Docker results
./tests/collect_test_results.sh --source local-docker --os ubuntu --version 24.04

# Auto-detect environment
./tests/collect_test_results.sh
```

### Compare Results

```bash
# Generate all comparison reports
./tests/report_discrepancies.sh --results tests/results

# Compare specific files
./tests/report_discrepancies.sh \
    --local tests/results/local-docker-ubuntu-24-20231228.json \
    --github tests/results/github-actions-ubuntu-24-20231228.json

# HTML report only
./tests/report_discrepancies.sh --results tests/results --format html
```

### Dual Environment Testing

```bash
# Run both local and GitHub tests, then compare
./tests/run_dual_environment_tests.sh --os ubuntu --version 24.04

# Compare existing results only
./tests/run_dual_environment_tests.sh --compare-only

# Upload results to GitHub
./tests/run_dual_environment_tests.sh --os ubuntu --version 24.04 --upload
```

### Understanding Comparison Reports

**Metrics:**
- **Pass Rate** - Percentage of tests passed
- **Congruence** - Similarity between environments (0-100%)
- **Accuracy Score** - Overall consistency measure (0-100%)

**Assessment Levels:**
- **EXCELLENT** (>95%) - Results are highly consistent
- **GOOD** (85-95%) - Minor discrepancies
- **FAIR** (70-85%) - Moderate discrepancies
- **POOR** (<70%) - Significant discrepancies

---

## Troubleshooting

### Docker Tests Fail

**Issue:** Container won't start
```bash
# Check Docker status
docker info
# Ensure daemon is running
sudo systemctl start docker
```

**Issue:** Permission denied
```bash
# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### GitHub Actions Tests Fail

**Issue:** Workflow not triggering
```bash
# Check workflow file syntax
yamllint .github/workflows/test-matrix.yml

# Verify GitHub authentication
gh auth status
```

### Test Results Missing

**Issue:** Results not generated
```bash
# Check results directory
ls -la tests/results/

# Collect manually
./tests/collect_test_results.sh --os ubuntu --version 24.04
```

### ShellCheck Errors

**Issue:** Linting fails in PR validation
```bash
# Check specific file
shellcheck tests/test_suite_smoke.sh

# Skip linting if intentional
./tests/validate_pr.sh --skip-lint
```

### Permission Errors in Container

**Issue:** Tests fail with permission denied
```bash
# Ensure container runs in privileged mode
docker run --privileged sysmaint-test:ubuntu-24.04
```

---

## Test Output

### Standard Output Format

```
========================================
SYSMAINT Test Suite
========================================

[TEST] Test name here
[PASS] Test name here

========================================
Test Summary
========================================
Tests run:    10
Tests passed: 10
Tests failed:  0

All tests passed!
```

### JSON Output Format

```json
{
  "version": "1.0",
  "run_id": "run-20231228-120000-hostname-1234",
  "timestamp": "2025-12-28T12:00:00Z",
  "environment": {
    "type": "local-docker",
    "os_name": "ubuntu",
    "os_version": "24.04",
    "architecture": "x86_64"
  },
  "results": {
    "smoke_tests": {
      "total": 10,
      "passed": 10,
      "failed": 0
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

---

## Best Practices

1. **Run quick tests before committing**
   ```bash
   ./tests/quick_test.sh
   ```

2. **Run PR validation before pushing**
   ```bash
   ./tests/validate_pr.sh
   ```

3. **Test on target OS locally first**
   ```bash
   ./tests/test_single_os.sh ubuntu 24.04
   ```

4. **Use parallel testing for multiple OS**
   ```bash
   ./tests/full_test.sh --os ubuntu-24,debian-12 --parallel
   ```

5. **Compare local vs CI results regularly**
   ```bash
   ./tests/run_dual_environment_tests.sh --compare-only
   ```

---

## Additional Resources

- **Test Matrix:** See [TEST_MATRIX.md](TEST_MATRIX.md)
- **OS Support:** See [OS_SUPPORT.md](OS_SUPPORT.md)
- **Test Architecture:** See [TEST_ARCHITECTURE.md](TEST_ARCHITECTURE.md)
- **Main README:** [README.md](../README.md)
