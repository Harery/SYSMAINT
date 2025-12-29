# SYSMAINT Test Matrix

**Version:** 1.0
**Last Updated:** 2025-12-28
**SPDX-License-Identifier:** MIT

## Table of Contents

1. [Overview](#overview)
2. [Test Suites](#test-suites)
3. [OS Coverage Matrix](#os-coverage-matrix)
4. [Feature Coverage](#feature-coverage)
5. [Test Execution Profiles](#test-execution-profiles)
6. [Quick Reference](#quick-reference)

---

## Overview

The SYSMAINT test matrix provides comprehensive coverage across all supported Linux distributions, execution modes, and features.

### Total Test Count

| Category | Suites | Total Tests |
|----------|--------|-------------|
| **Smoke Tests** | 1 | 10+ |
| **OS Family Tests** | 6 | 80+ |
| **Mode Tests** | 1 | 20+ |
| **Feature Tests** | 1 | 60+ |
| **Security Tests** | 1 | 40+ |
| **Performance Tests** | 1 | 15+ |
| **Edge Cases** | 1 | 30+ |
| **Integration** | 1 | 30+ |
| **Docker** | 1 | 40+ |
| **GitHub Actions** | 1 | 50+ |
| **TOTAL** | **14** | **500+** |

---

## Test Suites

### 1. Smoke Tests (`test_suite_smoke.sh`)

**Purpose:** Fast basic functionality validation

| Test ID | Test Name | Description |
|---------|-----------|-------------|
| SMOKE-001 | SYSMAINT executable accessible | Verifies sysmaint command exists |
| SMOKE-002 | Help command works | Tests --help output |
| SMOKE-003 | Version command works | Tests --version output |
| SMOKE-004 | OS detection works | Verifies correct OS detection |
| SMOKE-005 | Basic command parsing | Tests argument handling |
| SMOKE-006 | Bash shebang valid | Verifies script execution |
| SMOKE-007 | No syntax errors | ShellCheck passes |
| SMOKE-008 | File permissions correct | Executable bit set |
| SMOKE-009 | Required functions defined | Core functions exist |
| SMOKE-010 | Dry-run mode works | Tests --dry-run flag |

**Runtime:** ~10 seconds

### 2. Debian Family Tests (`test_suite_debian_family.sh`)

**Purpose:** Validate Debian/Ubuntu specific behavior

| Test ID | Test Name | Description |
|---------|-----------|-------------|
| DEB-001 | apt package manager detection | Detects apt availability |
| DEB-002 | dpkg installed | Verifies dpkg presence |
| DEB-003 | sources.list exists | Checks apt sources |
| DEB-004 | apt-get update works | Tests apt update |
| DEB-005 | apt upgrade works | Tests apt upgrade |
| DEB-006 | autoremove works | Tests autoremove |
| DEB-007 | Snap support (Ubuntu) | Tests snap package manager |
| DEB-008 | systemd-resolved (Ubuntu) | Tests DNS resolution |
| DEB-009 | AppArmor status | Tests security framework |
| DEB-010 | Debian release file | Verifies /etc/debian_version |

**Target OS:** Ubuntu 22.04, Ubuntu 24.04, Debian 12, Debian 13

### 3. RedHat Family Tests (`test_suite_redhat_family.sh`)

**Purpose:** Validate RHEL-based distributions

| Test ID | Test Name | Description |
|---------|-----------|-------------|
| RH-001 | dnf package manager detection | Detects dnf availability |
| RH-002 | yum fallback | Tests yum as fallback |
| RH-003 | rpm installed | Verifies rpm presence |
| RH-004 | SELinux status | Tests SELinux state |
| RH-005 | firewalld status | Tests firewall daemon |
| RH-006 | dnf upgrade works | Tests dnf upgrade |
| RH-007 | subscription-manager | Tests subscription tool |
| RH-008 | RHEL release file | Verifies /etc/redhat-release |
| RH-009 | Rocky Linux detection | Tests Rocky specific files |
| RH-010 | AlmaLinux detection | Tests Alma specific files |
| RH-011 | CentOS detection | Tests CentOS specific files |

**Target OS:** RHEL 9, RHEL 10, Rocky 9, Rocky 10, AlmaLinux 9, CentOS Stream 9

### 4. Arch Family Tests (`test_suite_arch_family.sh`)

**Purpose:** Validate Arch Linux

| Test ID | Test Name | Description |
|---------|-----------|-------------|
| ARCH-001 | pacman package manager detection | Detects pacman availability |
| ARCH-002 | makepkg installed | Verifies build tool |
| ARCH-003 | mirrorlist exists | Checks mirror configuration |
| ARCH-004 | multilib repo enabled | Tests 32-bit support |
| ARCH-005 | pacman -Syu works | Tests system upgrade |
| ARCH-006 | pacman -Rns works | Tests package removal |
| ARCH-007 | Arch release file | Verifies /etc/arch-release |
| ARCH-008 | pacman cache | Tests cache location |

**Target OS:** Arch Linux

### 5. SUSE Family Tests (`test_suite_suse_family.sh`)

**Purpose:** Validate openSUSE

| Test ID | Test Name | Description |
|---------|-----------|-------------|
| SUSE-001 | zypper package manager detection | Detects zypper availability |
| SUSE-002 | YaST installed | Tests configuration tool |
| SUSE-003 | zypper dup works | Tests distribution upgrade |
| SUSE-004 | zypper remove works | Tests package removal |
| SUSE-005 | SUSE release file | Verifies /etc/SuSE-release |

**Target OS:** openSUSE Tumbleweed

### 6. Fedora Tests (`test_suite_fedora.sh`)

**Purpose:** Validate Fedora 41

| Test ID | Test Name | Description |
|---------|-----------|-------------|
| FED-001 | dnf package manager detection | Detects dnf availability |
| FED-002 | modularity support | Tests DNF modules |
| FED-003 | RPM Fusion | Tests third-party repo |
| FED-004 | Flatpak support | Tests containerized apps |
| FED-005 | Fedora release file | Verifies /etc/fedora-release |

**Target OS:** Fedora 41

### 7. Cross-OS Compatibility (`test_suite_cross_os_compatibility.sh`)

**Purpose:** Validate behavior across all OS

| Test ID | Test Name | Description |
|---------|-----------|-------------|
| CROSS-001 | sysmaint executable | Works on all OS |
| CROSS-002 | --dry-run mode | Works on all OS |
| CROSS-003 | systemd detection | Detects systemd |
| CROSS-004 | package manager auto-detect | Detects correct PM |
| CROSS-005 | common paths exist | /tmp, /var, /etc exist |
| CROSS-006 | log directory writable | Can write logs |
| CROSS-007 | temp directory writable | Can use /tmp |
| CROSS-008 | sudo available | Tests sudo access |
| CROSS-009 | root check | Detects privileges |
| CROSS-010 | OS version detection | Correct version |

**Target OS:** All 14 OS versions

### 8. Mode Tests (`test_suite_modes.sh`)

**Purpose:** Validate execution modes

| Test ID | Test Name | Description |
|---------|-----------|-------------|
| MODE-001 | --auto mode | Non-interactive execution |
| MODE-002 | --gui mode | Interactive TUI |
| MODE-003 | --dry-run mode | Preview changes |
| MODE-004 | --quiet mode | Minimal output |
| MODE-005 | --verbose mode | Detailed output |
| MODE-006 | --json-summary mode | JSON output |
| MODE-007 | --upgrade flag | Package updates |
| MODE-008 | --cleanup flag | System cleanup |
| MODE-009 | --purge-kernels flag | Kernel removal |
| MODE-010 | --security-audit flag | Security checks |
| MODE-011 | Mode combinations | Multiple flags |
| MODE-012 | Invalid mode handling | Error handling |
| MODE-013 | Help mode | Documentation |
| MODE-014 | Version mode | Version info |

### 9. Feature Tests (`test_suite_features.sh`)

**Purpose:** Validate specific features

| Test ID | Test Name | Description |
|---------|-----------|-------------|
| FEAT-001 | Package management | All package operations |
| FEAT-002 | System cleanup | Cache and temp cleanup |
| FEAT-003 | Kernel purge | Old kernel removal |
| FEAT-004 | Security audit | Security checks |
| FEAT-005 | Firmware updates | fwupdmgr integration |
| FEAT-006 | Storage maintenance | fstrim, swap |
| FEAT-007 | Log rotation | Log management |
| FEAT-008 | Service management | systemd services |
| FEAT-009 | Backup functions | Backup operations |
| FEAT-010 | Snap packages | Ubuntu snap support |
| FEAT-011 | Flatpak packages | Flatpak support |
| FEAT-012 | JSON output | Structured output |

### 10. Security Tests (`test_suite_security.sh`)

**Purpose:** Security-focused validation

| Test ID | Test Name | Description |
|---------|-----------|-------------|
| SEC-001 | File permissions | Correct permissions |
| SEC-002 | File ownership | Root ownership |
| SEC-003 | GPG key validation | Package signing |
| SEC-004 | SELinux status | SELinux state |
| SEC-005 | AppArmor status | AppArmor state |
| SEC-006 | Firewall configuration | ufw/firewalld |
| SEC-007 | SSH configuration | SSH security |
| SEC-008 | Service security | Service permissions |
| SEC-009 | Repository security | Repo GPG checks |
| SEC-010 | Log file permissions | Log security |
| SEC-011 | Sudo requirements | Privilege escalation |
| SEC-012 | Root check | Privilege detection |
| SEC-013 | Temporary file cleanup | Temp file security |
| SEC-014 | Cache cleanup | Cache security |
| SEC-015 | Password policy | System security |

### 11. Performance Tests (`test_suite_performance.sh`)

**Purpose:** Performance benchmarking

| Test ID | Test Name | Description |
|---------|-----------|-------------|
| PERF-001 | Execution time | Total runtime |
| PERF-002 | Memory usage | RAM consumption |
| PERF-003 | Package operations speed | Package manager speed |
| PERF-004 | I/O performance | Disk operations |
| PERF-005 | Startup time | Script initialization |
| PERF-006 | Peak memory | Max RAM used |
| PERF-007 | CPU usage | Processor utilization |
| PERF-008 | Disk usage | Space consumption |
| PERF-009 | Network operations | Network calls |
| PERF-010 | Concurrent operations | Parallel execution |

**Target:** <3.5 minutes average runtime, <50MB memory

### 12. Edge Cases (`test_suite_edge_cases.sh`)

**Purpose:** Failure scenario testing

| Test ID | Test Name | Description |
|---------|-----------|-------------|
| EDGE-001 | No network | Offline mode |
| EDGE-002 | DNS failure | DNS handling |
| EDGE-003 | Package repo unavailable | Repo failure |
| EDGE-004 | Low disk space | Disk full handling |
| EDGE-005 | Temp directory cleanup | Temp cleanup |
| EDGE-006 | Disk space check | Space detection |
| EDGE-007 | Read-only filesystem | RO handling |
| EDGE-008 | No root privileges | Non-root execution |
| EDGE-009 | Sudo configuration | Sudo availability |
| EDGE-010 | Log file permissions | Log creation |
| EDGE-011 | Package manager not found | PM missing |
| EDGE-012 | Package lock handling | Lock files |
| EDGE-013 | Broken package cache | Cache corruption |
| EDGE-014 | SIGINT handling | Ctrl+C handling |
| EDGE-015 | SIGTERM handling | Termination |
| EDGE-016 | Cleanup on interrupt | Cleanup functions |
| EDGE-017 | Config file corruption | Invalid config |
| EDGE-018 | JSON parsing errors | Malformed JSON |
| EDGE-019 | Log file corruption | Log corruption |
| EDGE-020 | Parallel execution safe | Concurrent runs |
| EDGE-021 | PID file handling | PID management |
| EDGE-022 | Invalid command line args | Arg validation |
| EDGE-023 | Empty string arguments | Empty args |
| EDGE-024 | Special characters in args | Special chars |
| EDGE-025 | Memory handling | Low memory |
| EDGE-026 | File descriptor limits | FD limits |
| EDGE-027 | Process limits | Process limits |
| EDGE-028 | Missing environment variables | No env vars |
| EDGE-029 | PATH not set | No PATH |
| EDGE-030 | HOME not set | No HOME |

### 13. Integration Tests (`test_suite_integration.sh`)

**Purpose:** System integration validation

| Test ID | Test Name | Description |
|---------|-----------|-------------|
| INT-001 | Systemd available | systemd presence |
| INT-002 | Systemd timer file exists | Timer unit |
| INT-003 | Systemd service file exists | Service unit |
| INT-004 | Systemd timer syntax valid | Timer validation |
| INT-005 | Systemd service syntax valid | Service validation |
| INT-006 | SYSMAINT in PATH | PATH installation |
| INT-007 | Crontab syntax valid | Cron validation |
| INT-008 | Cron environment | Cron env vars |
| INT-009 | Weekly cron schedule | Cron syntax |
| INT-010 | Docker available | Docker presence |
| INT-011 | Docker daemon running | Docker status |
| INT-012 | Privileged mode check | Privileged detection |
| INT-013 | SYSMAINT in Docker image | Docker image |
| INT-014 | DEB package structure | Debian packaging |
| INT-015 | RPM package structure | RPM packaging |
| INT-016 | Install script exists | Install script |
| INT-017 | Uninstall script exists | Uninstall script |
| INT-018 | journald available | journald support |
| INT-019 | syslog available | syslog support |
| INT-020 | Log rotation configured | logrotate |
| INT-021 | SYSMAINT log directory | Log directory |
| INT-022 | Config directory exists | /etc/system-maintenance |
| INT-023 | Config file handling | Config loading |
| INT-024 | Default config works | No config behavior |
| INT-025 | Service status check | systemctl status |
| INT-026 | Failed services check | Failed units |
| INT-027 | Enabled services check | Enabled units |
| INT-028 | SELinux context | SELinux context |
| INT-029 | AppArmor profile | AppArmor status |
| INT-030 | Firewall integration | Firewall status |

### 14. Docker Tests (`test_suite_docker.sh`)

**Purpose:** Docker-specific testing

| Test ID | Test Name | Description |
|---------|-----------|-------------|
| DOCK-001 | Docker installed | Docker binary |
| DOCK-002 | Docker daemon running | Docker status |
| DOCK-003 | Docker can run bash | Container execution |
| DOCK-004 | Docker privileged access | Privileged mode |
| DOCK-005 | SYSMAINT Docker image exists | Image built |
| DOCK-006 | SYSMAINT Docker image executable | Image works |
| DOCK-007 | Docker container cleanup | No orphans |
| DOCK-008 | Privileged mode required | Privilege check |
| DOCK-009 | Systemd access in container | systemd in container |
| DOCK-010 | Host filesystem access | /host mount |
| DOCK-011 | Volume mount read-only | RO volumes |
| DOCK-012 | Volume mount read-write | RW volumes |
| DOCK-013 | Host root mount | Root mount |
| DOCK-014 | Container network isolation | Network |
| DOCK-015 | Container DNS resolution | DNS in container |
| DOCK-016 | Container can access apt | Package access |
| DOCK-017 | Dockerfile syntax valid | Dockerfile valid |
| DOCK-018 | Dockerfile has base image | FROM directive |
| DOCK-019 | Dockerfile installs dependencies | RUN install |
| DOCK-020 | Dockerfile copies SYSMAINT | COPY directive |
| DOCK-021 | Docker manifest support | Multi-arch |
| DOCK-022 | Multi-arch images available | amd64/arm64 |
| DOCK-023 | Docker Compose installed | compose binary |
| DOCK-024 | Docker Compose file exists | compose.yml |
| DOCK-025 | Docker Compose syntax valid | compose valid |
| DOCK-026 | Container memory limit | Memory limits |
| DOCK-027 | Container CPU limit | CPU limits |
| DOCK-028 | Container disk space | Disk available |
| DOCK-029 | Docker no root user | Non-root user |
| DOCK-030 | Docker read-only rootfs | Read-only FS |
| DOCK-031 | Docker security opt | Security options |
| DOCK-032 | Docker logging driver | Logging configured |
| DOCK-033 | Container logs accessible | docker logs |
| DOCK-034 | Docker log rotation configured | Log rotation |
| DOCK-035 | Can run multiple containers | Parallel execution |
| DOCK-036 | Container restart policy | Restart config |
| DOCK-037 | Container healthcheck | HEALTHCHECK |
| DOCK-038 | Docker volume creation | Volumes |
| DOCK-039 | Docker volume inspect | Volume info |
| DOCK-040 | Docker network creation | Networks |
| DOCK-041 | Docker network connect | Network connect |

### 15. GitHub Actions Tests (`test_suite_github_actions.sh`)

**Purpose:** CI/CD environment testing

| Test ID | Test Name | Description |
|---------|-----------|-------------|
| GHA-001 | GitHub Actions detected | CI detection |
| GHA-002 | GitHub workspace set | WORKSPACE env |
| GHA-003 | GitHub repository set | REPOSITORY env |
| GHA-004 | GitHub ref set | REF env |
| GHA-005 | GitHub SHA set | SHA env |
| GHA-006 | GitHub actor set | ACTOR env |
| GHA-007 | Runner OS detected | RUNNER_OS |
| GHA-008 | Runner arch detected | RUNNER_ARCH |
| GHA-009 | Runner temp available | RUNNER_TEMP |
| GHA-010 | Runner tool cache | TOOL_CACHE |
| GHA-011 | Workflow file exists | .yml file |
| GHA-012 | Workflow syntax valid | YAML valid |
| GHA-013 | Workflow has jobs | Jobs defined |
| GHA-014 | Workflow has matrix | Matrix strategy |
| GHA-015 | Matrix OS defined | OS in matrix |
| GHA-016 | Matrix version defined | Version in matrix |
| GHA-017 | Matrix OS variations | All OS listed |
| GHA-018 | Artifact upload configured | upload-artifact |
| GHA-019 | Artifact download configured | download-artifact |
| GHA-020 | Artifact retention set | retention-days |
| GHA-021 | Cache configured | actions/cache |
| GHA-022 | Cache key defined | Cache key |
| GHA-023 | Cache path defined | Cache paths |
| GHA-024 | Secrets not exposed | No hardcoded secrets |
| GHA-025 | Secret context used | secrets.* |
| GHA-026 | Checkout action used | actions/checkout |
| GHA-027 | Checkout depth configured | fetch-depth |
| GHA-028 | Bash available | bash in PATH |
| GHA-029 | Shell specified in workflow | shell: |
| GHA-030 | Permissions set | permissions: |
| GHA-031 | Contents read | contents: read |
| GHA-032 | Pull requests read | pull-requests: read |
| GHA-033 | Service container configured | services: |
| GHA-034 | Service image defined | image: |
| GHA-035 | Service ports configured | ports: |
| GHA-036 | Dependencies installed | apt/dnf install |
| GHA-037 | jq available | jq binary |
| GHA-038 | ShellCheck available | shellcheck |
| GHA-039 | Results directory exists | results/ |
| GHA-040 | Results JSON valid | JSON schema |
| GHA-041 | Results can be uploaded | Upload works |
| GHA-042 | Fail-fast defined | fail-fast: |
| GHA-043 | Max parallel defined | max-parallel: |
| GHA-044 | Job needs defined | needs: |
| GHA-045 | Job outputs | outputs: |
| GHA-046 | Push trigger | push: |
| GHA-047 | Pull request trigger | pull_request: |
| GHA-048 | Manual trigger | workflow_dispatch: |
| GHA-049 | Status check configured | Status checks |
| GHA-050 | Continue on error | continue-on-error: |
| GHA-051 | If condition | if: |
| GHA-052 | Timeout set | timeout-minutes: |
| GHA-053 | Timeout reasonable | <= 360 min |
| GHA-054 | Env vars set | env: |
| GHA-055 | CI env set | CI=true |
| GHA-056 | gh CLI available | gh binary |
| GHA-057 | gh auth | Auth status |
| GHA-058 | Step output | GITHUB_OUTPUT |
| GHA-059 | Summary output | GITHUB_STEP_SUMMARY |

---

## OS Coverage Matrix

### Full Test Coverage by OS

| OS | Version | Smoke | OS Family | Modes | Features | Security | Performance | Edge | Integration | Docker | GHA |
|----|---------|-------|-----------|-------|----------|----------|-------------|------|-------------|--------|-----|
| Ubuntu | 22.04 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Ubuntu | 24.04 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Debian | 12 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Debian | 13 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Fedora | 41 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| RHEL | 9 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| RHEL | 10 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Rocky | 9 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Rocky | 10 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| AlmaLinux | 9 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| CentOS | Stream 9 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Arch | Rolling | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| openSUSE | Tumbleweed | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

**Legend:** ✅ Tested | ⚠️ Partial | ❌ Not Started

---

## Feature Coverage

### Package Management

| Feature | Debian | RedHat | Arch | SUSE | Fedora |
|---------|--------|--------|------|------|--------|
| System Upgrade | ✅ | ✅ | ✅ | ✅ | ✅ |
| Auto-Remove | ✅ | ✅ | ✅ | ✅ | ✅ |
| Cache Cleaning | ✅ | ✅ | ✅ | ✅ | ✅ |
| Snap Support | ✅ | ❌ | AUR* | ❌ | ❌ |
| Flatpak Support | ✅ | ✅ | ✅ | ✅ | ✅ |

### System Maintenance

| Feature | Debian | RedHat | Arch | SUSE |
|---------|--------|--------|------|------|
| Kernel Purge | ✅ | ✅ | ✅ | ✅ |
| Log Rotation | ✅ | ✅ | ✅ | ✅ |
| Service Management | ✅ | ✅ | ✅ | ✅ |
| Firewall Config | ufw/iptables | firewalld | iptables* | firewalld |

### Security Features

| Feature | Debian | RedHat | Arch | SUSE |
|---------|--------|--------|------|------|
| SELinux | ❌ | ✅ | ❌ | ❌ |
| AppArmor | ✅ | ❌ | ❌ | ⚠️ |
| Security Audit | ✅ | ✅ | ✅ | ✅ |
| Firmware Updates | ✅ | ✅ | ✅ | ✅ |

---

## Test Execution Profiles

### Smoke Profile
**Duration:** ~10 seconds per OS
**Tests:** Basic functionality only
**Use Case:** Quick validation, PR checks

```
- test_suite_smoke.sh (10 tests)
```

### Standard Profile
**Duration:** ~2 minutes per OS
**Tests:** Core functionality validation
**Use Case:** Regular CI runs

```
- test_suite_smoke.sh
- test_suite_modes.sh
- test_suite_features.sh
```

### Full Profile
**Duration:** ~5 minutes per OS
**Tests:** All test suites
**Use Case:** Release validation

```
- test_suite_smoke.sh
- test_suite_<os_family>.sh
- test_suite_modes.sh
- test_suite_features.sh
- test_suite_security.sh
- test_suite_performance.sh
- test_suite_edge_cases.sh
- test_suite_integration.sh
```

### Performance Profile
**Duration:** ~10 minutes per OS
**Tests:** Performance benchmarks
**Use Case:** Performance regression detection

```
- test_suite_performance.sh
- test_suite_features.sh (timing)
```

---

## Quick Reference

### Running Tests

```bash
# Smoke test on current system
./tests/quick_test.sh

# Test specific OS in Docker
./tests/test_single_os.sh ubuntu 24.04

# Full test suite (local Docker)
./tests/full_test.sh --profile full

# Full test suite (GitHub Actions)
gh workflow run test-matrix.yml
```

### Test Result Locations

```
tests/results/
├── local-docker-<os>-<version>-<timestamp>.json
├── github-actions-<os>-<version>-<timestamp>.json
└── discrepancies/
    ├── <run-id>-report.txt
    ├── <run-id>-report.json
    └── <run-id>-report.html
```

### CI/CD Status

| Environment | Status | Notes |
|-------------|--------|-------|
| **GitHub Actions** | ✅ Active | 14 OS in parallel |
| **Local Docker** | ✅ Active | Manual/automated |
| **Result Comparison** | ✅ Active | Accuracy metrics |

---

## References

- [Test Guide](TEST_GUIDE.md) - How to run tests
- [Test Architecture](TEST_ARCHITECTURE.md) - Test structure design
- [OS Support](OS_SUPPORT.md) - OS compatibility
