# Platform Feature Compatibility Matrix

**Version:** v1.0.0
**Last Updated:** 2025-12-27
**Purpose:** Cross-platform compatibility reference for SYSMAINT

---

## Supported Platforms

| Family | Distribution | Version | Package Manager | Status |
|--------|--------------|---------|-----------------|--------|
| **Debian** | Ubuntu | 24.04, 22.04 | apt | ✅ Fully Supported |
| **Debian** | Debian | 13, 12 | apt | ✅ Fully Supported |
| **RedHat** | Fedora | 41 | dnf | ✅ Fully Supported |
| **RedHat** | RHEL | 10 | dnf | ✅ Fully Supported |
| **RedHat** | Rocky Linux | 9 | dnf | ✅ Fully Supported |
| **RedHat** | AlmaLinux | 9 | dnf | ✅ Fully Supported |
| **RedHat** | CentOS | Stream 9 | dnf | ✅ Fully Supported |
| **Arch** | Arch Linux | Rolling | pacman | ✅ Fully Supported |
| **SUSE** | openSUSE | Tumbleweed | zypper | ✅ Fully Supported |

---

## Feature Compatibility Matrix

### Core Features

| Feature | Debian/Ubuntu | Fedora/RHEL/Rocky/Alma/CentOS | Arch Linux | openSUSE |
|---------|---------------|-------------------------------|------------|----------|
| **System Update** | ✅ apt upgrade | ✅ dnf upgrade | ✅ pacman -Syu | ✅ zypper dup |
| **Package Cleanup** | ✅ autoremove | ✅ autoremove | ✅ orphan removal | ✅ orphan removal |
| **Cache Cleaning** | ✅ clean | ✅ clean | ✅ cache clean | ✅ clean |
| **Kernel Management** | ✅ | ✅ | ⚠️ N/A | ⚠️ N/A |
| **Snap Support** | ✅ | ✅ | ⚠️ Optional | ✅ |
| **Flatpak Support** | ✅ | ✅ | ✅ | ✅ |
| **Security Audit** | ✅ | ✅ | ✅ | ✅ |
| **JSON Output** | ✅ | ✅ | ✅ | ✅ |
| **GUI Mode** | ✅ | ✅ | ✅ | ✅ |
| **Dry Run Mode** | ✅ | ✅ | ✅ | ✅ |

---

## Platform-Specific Features

### Debian/Ubuntu Family

| Feature | Description | Status |
|---------|-------------|--------|
| APT operations | Full apt/dpkg support | ✅ |
| Old kernel removal | Automatic via /boot size check | ✅ |
| Snap updates | Channel tracking, refresh | ✅ |
| Flatpak updates | Automatic | ✅ |
| Debconf selection | Non-interactive frontend | ✅ |
| Journal cleanup | systemd-journal cleaning | ✅ |

---

### RedHat Family (Fedora/RHEL/Rocky/Alma/CentOS)

| Feature | Description | Status |
|---------|-------------|--------|
| DNF operations | Full dnf support | ✅ |
| Old kernel removal | Automatic via /boot size check | ✅ |
| Snap support | Available via snapd | ✅ |
| Flatpak updates | Automatic | ✅ |
| Package groups | Core group management | ✅ |
| Distro-sync | dnf distro-sync support | ✅ |

---

### Arch Linux

| Feature | Description | Status |
|---------|-------------|--------|
| Pacman operations | Full pacman support | ✅ |
| Orphan removal | Recursive dependency removal | ✅ |
| Cache cleaning | paccache integration | ✅ |
| AUR helper support | Optional yay/paru | ⚠️ Manual |
| Keyring management | archlinux-keyring sync | ✅ |
| Snap/Flatpak | Optional | ✅ |

---

### openSUSE

| Feature | Description | Status |
|---------|-------------|--------|
| Zypper operations | Full zypper support | ✅ |
| Patch management | Automatic patch management | ✅ |
| Orphan removal | Automatic | ✅ |
| Snap support | Available via snapd | ✅ |
| Flatpak updates | Automatic | ✅ |
| Vendor changes | Automatic handling | ✅ |

---

## Universal Features (All Platforms)

| Feature | Description |
|---------|-------------|
| **Dry Run Mode** | Preview changes without applying |
| **Verbose Mode** | Detailed output for debugging |
| **Quiet Mode** | Minimal output |
| **JSON Output** | Machine-readable structured output |
| **GUI Mode** | Interactive dialog-based menu |
| **Auto Mode** | Non-interactive automated execution |
| **Progress Tracking** | Visual progress bars |
| **Error Handling** | Graceful degradation |

---

## Detection & Auto-Configuration

SYSMAINT automatically detects:

| Detection Method | Purpose |
|-----------------|---------|
| OS ID | /etc/os-release parsing |
| Package Manager | Which package system to use |
| Init System | systemd vs openrc vs other |
| Container | Docker/LXC detection |
| Virtual Machine | VM detection for optimizations |

---

## Version Information

| Distribution | Version Detection Method |
|-------------|--------------------------|
| Debian/Ubuntu | `/etc/debian_version` or `VERSION_ID` |
| Fedora/RHEL/Rocky/Alma/CentOS | `/etc/redhat-release` or `VERSION_ID` |
| Arch Linux | Rolling (no version) |
| openSUSE | `/etc/os-release` |

---

**Document Version:** v1.0.0
**Project:** https://github.com/Harery/SYSMAINT
