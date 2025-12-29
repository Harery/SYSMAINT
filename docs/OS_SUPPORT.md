# SYSMAINT OS Support Matrix

**Version:** 1.0
**Last Updated:** 2025-12-28
**SPDX-License-Identifier:** MIT

## Overview

SYSMAINT supports 9 Linux distributions across 14 versions, covering the major package manager families.

## Quick Reference

| Status | Description |
|--------|-------------|
| ✅ **Fully Supported** | All features tested and working |
| ⚠️ **Partial Support** | Some features may have limitations |
| ❌ **Not Supported** | Known issues or not tested |

---

## Distribution Support

### Debian Family

#### Ubuntu

| Version | Code Name | Status | Package Manager | Notes |
|---------|-----------|--------|-----------------|-------|
| 22.04 | Jammy | ✅ Fully Supported | apt | LTS until 2027 |
| 24.04 | Noble | ✅ Fully Supported | apt | LTS until 2029 |

**Ubuntu-Specific:**
- Snap package support tested
- systemd-resolved DNS
- AppArmor security framework

#### Debian

| Version | Code Name | Status | Package Manager | Notes |
|---------|-----------|--------|-----------------|-------|
| 12 | Bookworm | ✅ Fully Supported | apt | Stable |
| 13 | Trixie | ✅ Fully Supported | apt | Testing |

**Debian-Specific:**
- No Snap by default
- Traditional systemd setup
- Common across multiple derivatives

---

### RedHat Family

#### RHEL (Red Hat Enterprise Linux)

| Version | Status | Package Manager | Notes |
|---------|--------|-----------------|-------|
| 9 | ✅ Fully Supported | dnf | Uses UBI for testing |
| 10 | ✅ Fully Supported | dnf | Uses UBI for testing |

**RHEL-Specific:**
- Subscription required (use UBI for testing)
- SELinux enabled by default
- firewalld default firewall

#### Rocky Linux

| Version | Status | Package Manager | Notes |
|---------|--------|-----------------|-------|
| 9 | ✅ Fully Supported | dnf | RHEL-compatible |
| 10 | ✅ Fully Supported | dnf | RHEL-compatible |

**Rocky-Specific:**
- Free RHEL alternative
- Same package management as RHEL
- No subscription required

#### AlmaLinux

| Version | Status | Package Manager | Notes |
|---------|--------|-----------------|-------|
| 9 | ✅ Fully Supported | dnf | RHEL-compatible |

**AlmaLinux-Specific:**
- Community-driven RHEL alternative
- 1:1 binary compatible with RHEL

#### CentOS Stream

| Version | Status | Package Manager | Notes |
|---------|--------|-----------------|-------|
| Stream 9 | ✅ Fully Supported | dnf | Rolling release |

**CentOS-Specific:**
- Upstream for RHEL
- Features before RHEL release

---

### Fedora

| Version | Status | Package Manager | Notes |
|---------|--------|-----------------|-------|
| 41 | ✅ Fully Supported | dnf | Latest stable |

**Fedora-Specific:**
- Leading-edge features
- Short release cycle
- Often first with new technologies

---

### Arch Linux

| Version | Status | Package Manager | Notes |
|---------|--------|-----------------|-------|
| Rolling | ✅ Fully Supported | pacman | Rolling release |

**Arch-Specific:**
- Rolling release model
- AUR support (untested in automation)
- KISS philosophy
- Very current packages

---

### SUSE Family

#### openSUSE

| Version | Status | Package Manager | Notes |
|---------|--------|-----------------|-------|
| Tumbleweed | ✅ Fully Supported | zypper | Rolling release |

**openSUSE-Specific:**
- YaST configuration tools
- Btrfs as default filesystem
- Rolling release with snapshots

---

## Package Manager Support

| Package Manager | Distributions | Tested Features |
|----------------|---------------|-----------------|
| **apt/apt-get** | Ubuntu, Debian | upgrade, autoremove, clean |
| **dnf** | Fedora, RHEL, Rocky, Alma, CentOS | upgrade, autoremove, clean |
| **pacman** | Arch | -Syu, -Rns, -Sc |
| **zypper** | openSUSE | dup, remove, clean |

---

## Feature Support by OS Family

### Package Management

| Feature | Debian | RedHat | Arch | SUSE |
|---------|--------|--------|------|------|
| System Upgrade | ✅ | ✅ | ✅ | ✅ |
| Auto-Remove | ✅ | ✅ | ✅ | ✅ |
| Cache Cleaning | ✅ | ✅ | ✅ | ✅ |
| Snap Support | Ubuntu | ❌ | AUR* | ❌ |
| Flatpak Support | ✅ | ✅ | ✅ | ✅ |

### System Maintenance

| Feature | Debian | RedHat | Arch | SUSE |
|---------|--------|--------|------|------|
| Kernel Purge | ✅ | ✅ | ✅ | ✅ |
| Log Rotation | ✅ | ✅ | ✅ | ✅ |
| Service Management | ✅ | ✅ | ✅ | ✅ |
| Firewall Config | ufw/iptables | firewalld | iptables* | firewalld/SuSEfirewall2 |

### Security Features

| Feature | Debian | RedHat | Arch | SUSE |
|---------|--------|--------|------|------|
| SELinux | ❌ | ✅ | ❌ | ❌ |
| AppArmor | ✅ | ❌ | ❌ | ⚠️ |
| Security Audit | ✅ | ✅ | ✅ | ✅ |
| Firmware Updates | ✅ | ✅ | ✅ | ✅ |

---

## Architecture Support

| Architecture | Status | Notes |
|--------------|--------|-------|
| **x86_64/amd64** | ✅ Primary | Fully supported |
| **arm64/aarch64** | ⚠️ Experimental | CI support planned |

---

## Version Support Policy

### Support Timeline

| Release Type | Support Duration |
|--------------|------------------|
| **Ubuntu LTS** | 5 years from release |
| **Debian Stable** | Until next stable + 2 years |
| **Fedora** | ~13 months per version |
| **RHEL** | 10 years |
| **Rocky/Alma** | Matches RHEL (10 years) |
| **Arch** | Rolling (no EOL) |
| **openSUSE Tumbleweed** | Rolling (no EOL) |

### Testing Priority

1. **High Priority** - Ubuntu LTS, Debian Stable
2. **Medium Priority** - Fedora, RHEL, Rocky, Alma
3. **Standard Priority** - Arch, openSUSE, CentOS

---

## Known Issues and Limitations

### Ubuntu

- None currently

### Debian

- None currently

### RHEL

- Requires subscription for production use
- Use UBI images for testing

### Fedora

- Frequent version updates may require test updates

### Rocky Linux

- None currently

### AlmaLinux

- None currently

### CentOS Stream

- None currently

### Arch Linux

- Rolling release requires regular test validation
- Package versions may vary between runs

### openSUSE

- YaST interactions not fully tested in automation

---

## Docker Image Availability

All test images are available for local testing:

```bash
# Build local images
docker build -f tests/docker/Dockerfile.ubuntu.test \
    --build-arg BASE_IMAGE=ubuntu:24.04 \
    -t sysmaint-test:ubuntu-24.04 .
```

See [TEST_GUIDE.md](TEST_GUIDE.md) for detailed instructions.

---

## Adding New OS Support

To add support for a new Linux distribution:

1. **Create Dockerfile** in `tests/docker/Dockerfile.<os>.test`
2. **Add to docker-compose** in `tests/docker/docker-compose.test.yml`
3. **Update OS_IMAGES** in `tests/run_local_docker_tests.sh`
4. **Create OS-specific test suite** in `tests/test_suite_<os>.sh`
5. **Add to test matrix** in `.github/workflows/test-matrix.yml`
6. **Update this document**

---

## Testing Matrix Status

| OS | Version | Smoke | OS Family | Modes | Features | Security | Performance |
|----|---------|-------|-----------|-------|----------|----------|-------------|
| Ubuntu | 22.04 | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| Ubuntu | 24.04 | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| Debian | 12 | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| Debian | 13 | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| Fedora | 41 | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| RHEL | 9 | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| RHEL | 10 | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| Rocky | 9 | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| Rocky | 10 | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| AlmaLinux | 9 | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| CentOS | Stream 9 | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| Arch | Rolling | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| openSUSE | Tumbleweed | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |

**Legend:** ✅ Complete | ⚠️ Partial | ❌ Not Started

---

## Contributing Test Results

When adding test results for a new OS:

1. Run the full test suite
2. Collect results using `collect_test_results.sh`
3. Submit results via PR or upload script
4. Update this document with findings

---

## References

- [Test Guide](TEST_GUIDE.md) - How to run tests
- [Test Matrix](TEST_MATRIX.md) - Comprehensive test coverage
- [Test Architecture](TEST_ARCHITECTURE.md) - Test structure design
