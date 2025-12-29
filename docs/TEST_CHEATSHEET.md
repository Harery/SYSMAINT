# SYSMAINT Test Commands Cheatsheet

**Version:** 1.0
**Last Updated:** 2025-12-28
**SPDX-License-Identifier:** MIT

---

## 🚀 Quick Reference

### Most Common Commands

```bash
# Quick validation (10 seconds)
bash tests/quick_test.sh

# Test current system only
bash tests/test_suite_smoke.sh

# Run all tests (standard profile)
bash tests/run_all_tests.sh

# Full test suite (comprehensive)
bash tests/run_all_tests.sh --profile full
```

---

## 📋 Test Profiles

| Profile | Duration | Tests | Use Case |
|---------|----------|-------|----------|
| `--profile smoke` | ~10s | 10+ | Quick validation |
| `--profile standard` | ~5m | 150+ | CI/CD runs |
| `--profile full` | ~15m | 250+ | Release validation |

---

## 🐳 Docker Testing

### Single OS Testing

```bash
# Ubuntu 24.04
bash tests/test_single_os.sh ubuntu 24.04

# Debian 12
bash tests/test_single_os.sh debian 12

# Fedora 41
bash tests/test_single_os.sh fedora 41
```

### Multiple OS (Local Docker)

```bash
# Single OS
./tests/run_local_docker_tests.sh --os ubuntu-24

# Multiple OS (series)
./tests/run_local_docker_tests.sh --os ubuntu-24,debian-12

# Multiple OS (parallel)
./tests/run_local_docker_tests.sh --os ubuntu-24,debian-12,fedora-41 --parallel

# All supported OS
./tests/run_local_docker_tests.sh --parallel
```

### Supported OS Identifiers

| Identifier | OS |
|------------|-----|
| `ubuntu-22`, `ubuntu-24` | Ubuntu 22.04, 24.04 |
| `debian-12`, `debian-13` | Debian 12, 13 |
| `fedora-41` | Fedora 41 |
| `rhel-9`, `rhel-10` | RHEL 9, 10 |
| `rocky-9`, `rocky-10` | Rocky Linux 9, 10 |
| `almalinux-9` | AlmaLinux 9 |
| `centos-9` | CentOS Stream 9 |
| `arch` | Arch Linux |
| `opensuse` | openSUSE Tumbleweed |

---

## 🔄 CI/CD Testing

### GitHub Actions

```bash
# Trigger test workflow
gh workflow run test-matrix.yml

# Trigger with specific profile
gh workflow run test-matrix.yml -f test_profile=smoke

# Trigger with OS filter
gh workflow run test-matrix.yml -f os_filter=ubuntu-24

# Watch workflow run
gh run watch

# List recent runs
gh run list

# Download artifacts
gh run download
```

### Dual Environment Comparison

```bash
# Compare local vs CI for Ubuntu 24.04
bash tests/run_dual_environment_tests.sh --os ubuntu --version 24.04

# Compare multiple OS
bash tests/run_dual_environment_tests.sh --os all --parallel
```

---

## 🧪 Individual Test Suites

### Core Suites

```bash
# Smoke tests
bash tests/test_suite_smoke.sh

# OS family tests
bash tests/test_suite_debian_family.sh
bash tests/test_suite_redhat_family.sh
bash tests/test_suite_arch_family.sh
bash tests/test_suite_suse_family.sh
bash tests/test_suite_fedora.sh
bash tests/test_suite_cross_os_compatibility.sh
```

### Functional Suites

```bash
# Execution modes
bash tests/test_suite_modes.sh

# Feature tests
bash tests/test_suite_features.sh

# Security tests
bash tests/test_suite_security.sh

# Performance tests
bash tests/test_suite_performance.sh
```

### Advanced Suites

```bash
# Edge cases
bash tests/test_suite_edge_cases.sh

# Integration tests
bash tests/test_suite_integration.sh

# Docker tests
bash tests/test_suite_docker.sh

# GitHub Actions tests
bash tests/test_suite_github_actions.sh
```

---

## 📊 Result Management

### Collect Results

```bash
# Collect current run results
bash tests/collect_test_results.sh

# Collect with verbose output
bash tests/collect_test_results.sh --verbose
```

### Compare Results

```bash
# Compare two result files
python3 tests/compare_test_results.py local.json github.json

# Generate text report
python3 tests/compare_test_results.py local.json github.json --format text

# Generate JSON report
python3 tests/compare_test_results.py local.json github.json --format json

# Generate HTML report
python3 tests/compare_test_results.py local.json github.json --format html
```

### Report Discrepancies

```bash
# Report all discrepancies
bash tests/report_discrepancies.sh --results tests/results

# Report with threshold
bash tests/report_discrepancies.sh --results tests/results --threshold 5
```

### Upload Results

```bash
# Upload to GitHub
bash tests/upload_test_results.sh --run-id 123

# Upload with custom path
bash tests/upload_test_results.sh --run-id 123 --path tests/results
```

---

## 🔧 Advanced Options

### OS Filtering

```bash
# Test Debian family only
bash tests/run_all_tests.sh --profile standard --os-filter debian

# Test RedHat family only
bash tests/run_all_tests.sh --profile standard --os-filter redhat

# Test Arch only
bash tests/run_all_tests.sh --profile standard --os-filter arch
```

### Verbose Output

```bash
# Run with verbose output
bash tests/run_all_tests.sh --profile smoke --verbose

# Run individual suite with output
bash tests/test_suite_smoke.sh
```

### Dry Run

```bash
# Show what would run
bash tests/run_all_tests.sh --profile full --dry-run
```

---

## 🎯 Common Workflows

### Before Committing Code

```bash
# Quick smoke test
bash tests/quick_test.sh

# Or smoke profile
bash tests/run_all_tests.sh --profile smoke
```

### Before Creating PR

```bash
# Run validation
bash tests/validate_pr.sh

# Or standard tests
bash tests/run_all_tests.sh --profile standard
```

### Before Release

```bash
# Full test suite
bash tests/run_all_tests.sh --profile full

# Dual environment comparison
bash tests/run_dual_environment_tests.sh --os all
```

### Testing Specific Changes

```bash
# Only package management tests
bash tests/test_suite_features.sh

# Only security tests
bash tests/test_suite_security.sh

# Only Docker tests
bash tests/test_suite_docker.sh
```

---

## 🐛 Troubleshooting

### Docker Issues

```bash
# Check Docker daemon
docker info

# Rebuild test images
docker rmi sysmaint-test:*
bash tests/run_local_docker_tests.sh --rebuild

# Test Docker access
docker run --rm --privileged alpine:latest uptime
```

### Test Failures

```bash
# Check test logs
cat /tmp/test-suite-*-*.log

# Run with verbose output
bash tests/test_suite_smoke.sh

# Check results directory
ls -la tests/results/
```

### CI/CD Issues

```bash
# Check workflow syntax
yamllint .github/workflows/test-matrix.yml

# Validate workflows
gh workflow view test-matrix.yml

# Trigger manual run
gh workflow run test-matrix.yml
```

---

## 📈 Performance Benchmarks

### Run Benchmarks

```bash
# Full benchmarks
bash tests/benchmarks.sh

# Performance suite
bash tests/test_suite_performance.sh

# Check regression
bash tests/check_performance_regression.sh --baseline tests/baseline.json
```

---

## 🔍 Test Discovery

### List All Test Suites

```bash
ls -1 tests/test_suite_*.sh
```

### Count Tests

```bash
# Count total test files
ls -1 tests/test_suite_*.sh | wc -l

# Count automation scripts
ls -1 tests/*.sh | grep -v test_suite | wc -l
```

### Find Specific Tests

```bash
# Find Docker-related tests
ls -1 tests/test_suite_*docker*.sh

# Find security tests
ls -1 tests/test_suite_*security*.sh

# Find performance tests
ls -1 tests/test_suite_*performance*.sh
```

---

## 📞 Getting Help

### Built-in Help

```bash
# Master runner help
bash tests/run_all_tests.sh --help

# Individual suite info
head -20 tests/test_suite_smoke.sh
```

### Documentation

| File | Purpose |
|------|---------|
| `docs/TEST_GUIDE.md` | Complete testing guide |
| `docs/TEST_MATRIX.md` | All 500+ tests documented |
| `docs/TEST_ARCHITECTURE.md` | Test design documentation |
| `docs/TEST_SUMMARY.md` | Infrastructure overview |
| `docs/TEST_CHEATSHEET.md` | This file |

---

## ⚡ Pro Tips

1. **Use `--profile smoke`** for quick feedback during development
2. **Use `--parallel`** with Docker tests for faster results
3. **Run `validate_pr.sh`** before submitting pull requests
4. **Use dry-run mode** to see what tests will execute
5. **Check results JSON** for automated parsing
6. **Use OS filters** to test specific distributions
7. **Compare environments** to catch CI-specific issues
8. **Keep test logs** for debugging failures

---

## 🎓 Learning Path

1. Start with `quick_test.sh` to verify basic functionality
2. Try `run_all_tests.sh --profile smoke` for more coverage
3. Explore individual test suites to understand areas
4. Use Docker testing for cross-OS validation
5. Set up CI/CD comparison for accuracy tracking
6. Contribute new tests for features you add

---

**Maintained by:** @Harery
**Last Updated:** 2025-12-28
**Version:** 1.0
