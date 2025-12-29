# SYSMAINT Test Infrastructure

Comprehensive test infrastructure with 500+ tests across 9 Linux distributions and 14 OS versions.

## 🚀 Quick Start

```bash
# Quick validation (10 seconds)
bash tests/quick_test.sh

# Test specific OS in Docker
bash tests/test_single_os.sh ubuntu 24.04

# Run all tests
bash tests/run_all_tests.sh --profile standard
```

## 📊 Test Statistics

| Metric | Count |
|--------|-------|
| Test Suites | 32 |
| Test Cases | 500+ |
| OS Distributions | 9 |
| OS Versions | 14 |
| Automation Scripts | 25 |
| Documentation Files | 15 |

## 📁 Directory Structure

```
tests/
├── test_suite_*.sh           # 32 test suites
├── quick_test.sh              # Fast validation
├── run_all_tests.sh           # Master test runner
├── test_single_os.sh          # Single OS testing
├── run_local_docker_tests.sh  # Docker matrix testing
├── run_dual_environment_tests.sh # Environment comparison
├── validate_pr.sh             # PR validation
├── generate_test_report.sh    # HTML report generator
├── collect_metrics.sh         # Metrics collection
├── populate_performance_baselines.sh # Performance data
├── test-dashboard.html        # Interactive visualization
├── docker/                    # 9 Docker test images
├── templates/                 # Test templates
├── results/                   # Test results (gitignored)
├── PERFORMANCE_BASELINES.md   # Performance targets
├── STATUS_ASSESSMENT.md       # Project completion status
└── VALIDATION_REPORT.md       # Validation results
```

## 🧪 Test Suites

### Core Suites
- `test_suite_smoke.sh` - Basic functionality tests
- `test_suite_modes.sh` - Execution mode tests
- `test_suite_features.sh` - Feature-specific tests
- `test_suite_security.sh` - Security validation

### OS Family Suites
- `test_suite_debian_family.sh` - Debian/Ubuntu tests
- `test_suite_redhat_family.sh` - RHEL/Fedora/Rocky/Alma tests
- `test_suite_arch_family.sh` - Arch Linux tests
- `test_suite_suse_family.sh` - openSUSE tests
- `test_suite_fedora.sh` - Fedora-specific tests
- `test_suite_cross_os_compatibility.sh` - Multi-OS tests

### Specialized Suites
- `test_suite_performance.sh` - Performance benchmarks
- `test_suite_edge_cases.sh` - Edge case testing
- `test_suite_integration.sh` - Integration tests
- `test_suite_docker.sh` - Docker environment tests
- `test_suite_github_actions.sh` - CI/CD tests

## 🐳 Docker Testing

Test across all supported OS locally using Docker:

```bash
# Single OS
bash tests/run_local_docker_tests.sh --os ubuntu-24.04

# Multiple OS (parallel)
bash tests/run_local_docker_tests.sh --os ubuntu-24,debian-12,fedora-41 --parallel

# All supported OS
bash tests/run_local_docker_tests.sh --all
```

### Available Docker Images

| Distribution | Versions |
|--------------|----------|
| Ubuntu | 22.04, 24.04 |
| Debian | 12, 13 |
| Fedora | 41 |
| RHEL | 9, 10 |
| Rocky Linux | 9, 10 |
| AlmaLinux | 9 |
| CentOS | Stream 9 |
| Arch Linux | Rolling |
| openSUSE | Tumbleweed |

## 📋 Test Profiles

| Profile | Duration | Description |
|---------|----------|-------------|
| `smoke` | ~10s | Quick validation tests |
| `standard` | ~5m | Pre-commit test suite |
| `full` | ~15m | Complete validation |

```bash
bash tests/run_all_tests.sh --profile smoke
bash tests/run_all_tests.sh --profile standard
bash tests/run_all_tests.sh --profile full
```

## 📊 Result Management

### Collect Results
```bash
bash tests/collect_test_results.sh
```

### Generate HTML Report
```bash
bash tests/generate_test_report.sh --output my-report.html
```

### Compare Environments
```bash
bash tests/run_dual_environment_tests.sh --os ubuntu --version 24.04
```

### View Dashboard
Open `tests/test-dashboard.html` in a browser for interactive visualization.

## 📈 Performance Testing

```bash
# Run performance benchmarks
bash tests/test_suite_performance.sh

# Collect baseline data
bash tests/populate_performance_baselines.sh

# View performance targets
cat tests/PERFORMANCE_BASELINES.md
```

## 🔧 CI/CD Integration

### GitHub Actions
- **test-matrix.yml** - Multi-OS parallel testing
- **ci.yml** - Enhanced CI pipeline
- **docker.yml** - Docker image builds
- **release.yml** - Release automation

### Result Artifacts
Test results are automatically uploaded as GitHub Actions artifacts.

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [TEST_QUICKSTART.md](../docs/TEST_QUICKSTART.md) | 5-minute getting started guide |
| [TEST_GUIDE.md](../docs/TEST_GUIDE.md) | Comprehensive testing guide |
| [TEST_CHEATSHEET.md](../docs/TEST_CHEATSHEET.md) | Quick command reference |
| [TEST_MATRIX.md](../docs/TEST_MATRIX.md) | Complete 500+ test inventory |
| [TEST_SUMMARY.md](../docs/TEST_SUMMARY.md) | Infrastructure overview |
| [TEST_ARCHITECTURE.md](../docs/TEST_ARCHITECTURE.md) | Design documentation |
| [TEST_TROUBLESHOOTING.md](../docs/TEST_TROUBLESHOOTING.md) | Problem solving |
| [CONTRIBUTING_TESTS.md](../docs/CONTRIBUTING_TESTS.md) | Contribution guide |

## 🎯 Test Categories

| Category | Suites | Tests |
|----------|--------|-------|
| Smoke Tests | 1 | 10+ |
| OS Family | 6 | 80+ |
| Execution Modes | 1 | 20+ |
| Features | 1 | 60+ |
| Security | 1 | 40+ |
| Performance | 1 | 20+ |
| Edge Cases | 2 | 30+ |
| Integration | 1 | 30+ |
| Docker | 1 | 40+ |
| GitHub Actions | 1 | 50+ |
| Additional | 16 | 160+ |

## 🔍 Safety

- All default tests use `--dry-run` mode
- No system changes during test execution
- Mock binaries available for isolated testing
- Docker isolation for OS-specific tests

## 📞 Support

- **Issues:** https://github.com/Harery/SYSMAINT/issues
- **Discussions:** https://github.com/Harery/SYSMAINT/discussions
- **Documentation:** See docs/TEST_*.md

---

**Status:** ✅ 100% Complete - Production Ready
**Coverage:** 9 distributions, 14 versions, 500+ tests
**Last Updated:** 2025-12-28

---

**SPDX-License-Identifier:** MIT
**Copyright (c) 2025 Harery**
