# 🚀 SYSMAINT Release Roadmap

**Document Version:** 1.0  
**Last Updated:** 4 December 2025  
**Maintainer:** Harery

---

## 📋 Table of Contents

1. [Current Stable Release](#current-stable-release)
2. [Continuing Support & Maintenance](#continuing-support--maintenance)
3. [Planned Future Releases](#planned-future-releases)
   - [Release v2.2.0 - Multi-Distro Support](#release-v220---multi-distro-support)
   - [Release v2.3.0 - TBD](#release-v230---tbd)
   - [Release v3.0.0 - Dual Mode (CLI + GUI)](#release-v300---dual-mode-cli--gui)
4. [Version Timeline](#version-timeline)
5. [Performance Targets](#performance-targets)

---

## 🎯 Current Stable Release

### **v2.1.2** - Production Quality & CI Integration
**Released:** November 2025  
**Status:** ✅ Stable Production Release

#### Supported Platforms
- Ubuntu 20.04+
- Debian 10+
- Debian-based distributions

#### Key Features
- 246 comprehensive test cases
- Automated CI/CD pipelines (GitHub Actions)
- Docker containerization support
- `.deb` package distribution
- JSON telemetry output with schema validation
- 12 pre-built maintenance profiles
- Systemd timer integration

#### Installation Methods
1. **APT/DEB Package** (recommended)
2. **Docker Container** (GitHub Packages)
3. **Manual Installation** (Git clone)

📦 [Download v2.1.2](https://github.com/Harery/SYSMAINT/releases/tag/v2.1.2)

---

## 🔄 Continuing Support & Maintenance

### Active Maintenance (v2.1.x)
- Security patches and bug fixes
- Documentation updates
- Performance optimizations
- Community support and issue resolution
- CI/CD pipeline improvements

### Long-Term Support
- v2.1.2 will receive maintenance updates until v2.3.0 is released
- Critical security fixes backported to v2.1.x series
- Community-driven enhancements reviewed on case-by-case basis

---

## 🗺️ Planned Future Releases

### **Release v2.2.0** - Multi-Distro Support
**Target:** Q1 2026  
**Status:** 📋 Planning Phase  
**Performance Target:** Baseline <3.0s (-3% improvement)

#### Stakeholder Requirements
Expand SYSMAINT compatibility beyond Debian-based distributions to support major Linux distribution families.

#### Development Phases

##### 🔴 **Phase 1: Red Hat Family Support**
**Target:** Early Q1 2026

**Supported Distributions:**
- Red Hat Enterprise Linux (RHEL) 8+
- CentOS Stream 8+
- Fedora 38+

**Technical Implementation:**
- Replace `apt`/`dpkg` commands with `dnf`/`rpm` equivalents
- Adapt package manager operations for YUM/DNF
- Update system update mechanisms (`dnf update`)
- Modify package cleanup logic for Red Hat ecosystem
- Create `.rpm` package distribution

**Testing Requirements:**
- Test suite expansion for RHEL/CentOS/Fedora
- CI/CD pipeline addition for RPM-based systems
- Validation on RHEL 8, 9 and Fedora 38, 39, 40

##### 🟢 **Phase 2: Other Linux Distributions**
**Target:** Mid Q1 2026

**Supported Distributions:**
- Linux Mint (all editions)
- Manjaro Linux
- Arch Linux
- openSUSE Leap/Tumbleweed (potential)

**Technical Implementation:**
- Pacman package manager support (Arch/Manjaro)
- Mint-specific optimizations (Ubuntu/Debian base consideration)
- Zypper support evaluation (openSUSE)
- Rolling release compatibility testing
- AUR package creation for Arch ecosystem

**Testing Requirements:**
- Test coverage for Pacman operations
- Arch/Manjaro stability validation
- Mint compatibility verification
- Rolling release update handling

##### 🔵 **Phase 3: Auto-Detection & Path Selection**
**Target:** Late Q1 2026

**Technical Implementation:**
- **Distribution Detection:**
  - Parse `/etc/os-release` for distro identification
  - Kernel version detection via `uname -r`
  - Package manager auto-discovery
  - Init system detection (systemd/OpenRC/sysvinit)

- **Intelligent Path Routing:**
  - Conditional execution paths based on distro family
  - Package manager wrapper abstraction layer
  - Distro-specific command mapping
  - Graceful fallback mechanisms

- **User Experience:**
  - Automatic distro detection on first run
  - Clear logging of detected environment
  - Override flags for manual distro specification
  - Comprehensive distro compatibility matrix

**Testing Requirements:**
- Multi-distro test matrix (minimum 8 distributions)
- Containerized testing environment (Docker)
- Detection accuracy validation
- Edge case handling (unknown/custom distros)

#### Deliverables (v2.2.0)
- ✅ Multi-distro bash script with auto-detection
- ✅ `.deb`, `.rpm`, and Arch AUR packages
- ✅ Updated documentation for all supported distros
- ✅ Expanded test suite (300+ tests)
- ✅ Multi-distro CI/CD pipeline
- ✅ Docker images for RHEL/Fedora/Arch bases

---

### **Release v2.3.0** - TBD
**Target:** Q2 2026  
**Status:** 📋 Requirements Gathering  
**Performance Target:** Maximum <4.5s (-10% improvement)

#### Planned Focus Areas (Tentative)
- Performance optimizations from v2.2.0 learnings
- Enhanced telemetry and reporting
- Additional pre-built profiles
- Community-requested features backlog

*Detailed requirements to be finalized after v2.2.0 release.*

---

### **Release v3.0.0** - Dual Mode (CLI + GUI)
**Target:** Q3-Q4 2026  
**Status:** 🔮 Stakeholder Review  
**Performance Target:** Baseline <2.5s (-20% improvement)

#### Stakeholder Requirements (Preliminary)
Transform SYSMAINT into a **dual-capability** system maintenance tool supporting both command-line and graphical user interface modes.

#### High-Level Vision

##### **Mode 1: Command-Line Interface (Current)**
- Maintain 100% backward compatibility with v2.x CLI
- All existing flags, options, and behavior preserved
- Scriptable, automation-friendly
- Optimal for server environments and SSH sessions

##### **Mode 2: Interactive GUI (New)**
- **Matrix Selection Interface:**
  - Visual selection of maintenance tasks
  - Interactive checkbox-style operation picker
  - Real-time preview of selected operations
  - Estimated time and impact indicators

- **User Experience:**
  - TUI (Terminal User Interface) or GUI application
  - Color-coded operation categories
  - Progress bars and status indicators
  - Summary screen before execution

- **Technical Considerations (Pending):**
  - TUI framework evaluation (Dialog, Whiptail, ncurses)
  - GUI framework options (GTK, Qt, Electron)
  - Mode selection mechanism (`--gui` flag or separate binary)
  - Configuration persistence between modes

#### Open Questions (Awaiting Stakeholder Input)
- 🤔 TUI vs. GUI framework preference?
- 🤔 Single binary with mode flag or separate binaries?
- 🤔 Minimum supported display resolution/terminal size?
- 🤔 Mouse support requirement?
- 🤔 Profile management in GUI mode?
- 🤔 Remote GUI execution support (X11 forwarding)?

#### Provisional Deliverables (v3.0.0)
- 🔲 Dual-mode executable (CLI + GUI/TUI)
- 🔲 Interactive matrix selection interface
- 🔲 GUI/TUI installation packages
- 🔲 Updated documentation for both modes
- 🔲 GUI-specific test coverage
- 🔲 Enhanced user manual with screenshots/recordings

*Detailed requirements and implementation plan pending stakeholder clarification.*

---

## 📅 Version Timeline

```
2025 Q4          2026 Q1          2026 Q2          2026 Q3          2026 Q4
   |                |                |                |                |
   v2.1.2      Phase 1 →        v2.3.0          v3.0.0 Dev      v3.0.0 Release
  (Current)    Phase 2 →       (Optimize)       (GUI Start)      (Dual Mode)
              Phase 3 →
              v2.2.0 →
          (Multi-Distro)
```

### Milestone Summary

| Version | Target Date | Status | Key Feature |
|---------|-------------|--------|-------------|
| v2.1.2  | Nov 2025 ✅ | Released | CI/CD, Docker, Production Quality |
| v2.2.0  | Q1 2026 📋 | Planning | Multi-Distro Support (RHEL/Arch/etc.) |
| v2.3.0  | Q2 2026 📋 | TBD | Performance & Optimization |
| v3.0.0  | Q3-Q4 2026 🔮 | Vision | Dual Mode (CLI + GUI) |

---

## ⚡ Performance Targets

| Version | Baseline Target | Maximum Target | Improvement | Status |
|---------|----------------|----------------|-------------|--------|
| v2.1.1  | 3.1s | 4.8s | Baseline | ✅ Achieved |
| v2.1.2  | 3.1s | 4.8s | Stable | ✅ Current |
| v2.2.0  | <3.0s | <4.5s | -3% | 📋 Target |
| v2.3.0  | <2.8s | <4.5s | -10% | 📋 Target |
| v3.0.0  | <2.5s | <4.0s | -20% | 🔮 Goal |

### Performance Measurement
- **Baseline:** Average execution time for `--full` profile on standard hardware
- **Maximum:** 95th percentile execution time across test suite
- **Test Environment:** Ubuntu 22.04 LTS, 4-core CPU, 8GB RAM, SSD storage

---

## 🤝 Contributing to Releases

### Feedback & Requirements
- Open GitHub issues with `enhancement` label for feature requests
- Comment on milestone issues for ongoing releases
- Join discussions in project GitHub Discussions

### Development Participation
- Check open issues tagged with release milestones
- Review PRs targeting upcoming releases
- Test pre-release builds and report findings

### Stakeholder Communication
- Major requirement changes documented in this file
- Release status updates in `CHANGELOG.md`
- Technical implementation details in relevant issue tickets

---

## 📚 Related Documentation

- [CHANGELOG.md](CHANGELOG.md) - Detailed version history
- [FEATURES.md](FEATURES.md) - Current feature documentation
- [README.md](README.md) - Quick start and installation
- [docs/PERFORMANCE.md](docs/PERFORMANCE.md) - Performance benchmarks and targets
- [docs/SECURITY.md](docs/SECURITY.md) - Security policies and updates

---

**Project:** [SYSMAINT](https://github.com/Harery/SYSMAINT)  
**License:** MIT  
**Maintainer:** Harery  
**Last Updated:** 4 December 2025
