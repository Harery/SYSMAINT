# SYSMAINT Test Coverage Matrix

**Version:** v1.0.0
**Last Updated:** 2025-12-27

---

## Overview

This document describes the test coverage for SYSMAINT across supported platforms.

### Test Statistics

| Metric | Count |
|--------|-------|
| **Test Suites** | 14 |
| **Test Files** | 30+ |
| **OS Families** | 4 (Debian, RedHat, Arch, SUSE) |
| **Supported Distributions** | 9 |
| **Test Categories** | 12 |

---

## Supported Platforms

| Distribution | Version | Package Manager | Test Coverage |
|--------------|---------|-----------------|---------------|
| Ubuntu | 24.04, 22.04 | apt | ✅ Full |
| Debian | 13, 12 | apt | ✅ Full |
| Fedora | 41 | dnf | ✅ Full |
| RHEL | 10 | dnf | ✅ Full |
| Rocky Linux | 9 | dnf | ✅ Full |
| AlmaLinux | 9 | dnf | ✅ Full |
| CentOS | Stream 9 | dnf | ✅ Full |
| Arch Linux | Rolling | pacman | ✅ Full |
| openSUSE | Tumbleweed | zypper | ✅ Full |

---

## Test Suites

| Suite | Purpose | Status |
|-------|---------|--------|
| `test_suite_smoke.sh` | Basic functionality | ✅ |
| `test_suite_functions.sh` | Core functions | ✅ |
| `test_suite_security.sh` | Security checks | ✅ |
| `test_suite_performance.sh` | Performance benchmarks | ✅ |
| `test_suite_os_families.sh` | OS family detection | ✅ |
| `test_suite_gui_mode.sh` | Interactive mode | ✅ |
| `test_suite_json_validation.sh` | JSON output | ✅ |
| `test_suite_docker_detection.sh` | Docker detection | ✅ |
| `test_profile_ci.sh` | CI profile | ✅ |
| `test_suite_realmode_sandbox.sh` | Real mode sandbox | ✅ |
| `test_suite_parallel_execution.sh` | Parallel tests | ✅ |
| `test_suite_error_handling.sh` | Error scenarios | ✅ |
| `test_suite_governance.sh` | Governance checks | ✅ |
| `test_suite_environment.sh` | Environment tests | ✅ |

---

## Test Categories

### Core Functionality

| Test | Description |
|------|-------------|
| Package updates | Correct package manager commands |
| Package cleanup | Orphan removal, cache cleaning |
| Kernel management | Old kernel removal |
| Snap support | Snap detection and updates |
| Flatpak support | Flatpak detection and updates |
| JSON output | Valid JSON generation |

### Platform Detection

| Test | Description |
|------|-------------|
| OS detection | Correct /etc/os-release parsing |
| Package manager detection | Correct package manager selection |
| Platform module loading | Correct platform module sourced |
| Container detection | Docker/LXC detection |
| VM detection | Virtual machine detection |

### Error Handling

| Test | Description |
|------|-------------|
| Missing tools | Graceful fallback |
| Permission errors | Proper error messages |
| Network failures | Timeout handling |
| Package lock issues | Lock detection |

### Performance

| Test | Description |
|------|-------------|
| Runtime benchmarks | Execution time measurement |
| Memory usage | Memory footprint |
| Parallel execution | Concurrent operation support |

---

## Running Tests

### Run All Tests

```bash
cd /path/to/sysmaint
bash tests/test_suite_smoke.sh
```

### Run Specific Test

```bash
bash tests/test_suite_os_families.sh
```

### Run with Debug Output

```bash
DEBUG_TESTS=true bash tests/test_suite_smoke.sh
```

### Run Performance Tests

```bash
bash tests/benchmarks.sh
```

---

## Test Results Interpretation

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All tests passed |
| 1 | One or more tests failed |
| 2 | Test setup error |
| 127 | Required tool missing |

### Test Output Format

```
[TEST] Test name
[PASS] Description
[FAIL] Description
[SKIP] Description (test not applicable)
```

---

## Platform-Specific Test Notes

### Debian/Ubuntu

- Tests APT package operations
- Validates dpkg database queries
- Tests Snap integration
- Validates debconf non-interactive mode

### RedHat Family

- Tests DNF package operations
- Validates RPM database queries
- Tests Snap integration
- Validates groupinstall operations

### Arch Linux

- Tests pacman operations
- Validates pacman database queries
- Tests orphan removal
- Validates keyring sync

### openSUSE

- Tests zypper operations
- Tests patch management
- Validates vendor change handling

---

## Test File Structure

```
tests/
├── README.md                      # Test documentation
├── test_suite_smoke.sh            # Basic smoke tests
├── test_suite_functions.sh        # Function tests
├── test_suite_security.sh         # Security tests
├── test_suite_performance.sh      # Performance tests
├── test_suite_os_families.sh      # OS family tests
├── test_suite_gui_mode.sh         # GUI mode tests
├── test_suite_json_validation.sh  # JSON validation
├── test_suite_docker_detection.sh # Docker detection
├── test_profile_ci.sh             # CI profile
├── test_suite_realmode_sandbox.sh # Sandbox tests
├── test_suite_parallel_execution.sh # Parallel tests
├── test_suite_error_handling.sh   # Error handling
├── test_suite_governance.sh       # Governance tests
├── test_suite_environment.sh      # Environment tests
├── benchmarks.sh                  # Benchmark runner
├── generate_summary.sh            # Summary generator
├── generate_html_report.sh        # HTML report
├── check_performance_regression.sh # Regression check
├── cross_os_test_runner.sh        # Cross-OS runner
├── test_profiles.yaml             # Test profiles
└── validate_json.py               # JSON validator
```

---

**Document Version:** v1.0.0
**Project:** https://github.com/Harery/SYSMAINT
