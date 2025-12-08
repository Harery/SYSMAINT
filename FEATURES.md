# 🚀 Sysmaint Features & Capabilities

> **Your complete guide to automated multi-distro Linux system maintenance**

[![Release](https://img.shields.io/github/v/release/Harery/SYSMAINT?label=release&color=green)](https://github.com/Harery/SYSMAINT/releases/latest)
[![Docker](https://img.shields.io/badge/docker-ghcr.io-blue?logo=docker)](https://github.com/Harery/SYSMAINT/pkgs/container/sysmaint)
[![CI](https://github.com/Harery/SYSMAINT/actions/workflows/ci.yml/badge.svg)](https://github.com/Harery/SYSMAINT/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/tests-281%20passing-brightgreen)](https://github.com/Harery/SYSMAINT)
[![Coverage](https://img.shields.io/badge/coverage-100%25-brightgreen)](https://github.com/Harery/SYSMAINT)
[![Enterprise](https://img.shields.io/badge/RHEL-validated-red.svg)](https://github.com/Harery/SYSMAINT)

---

## 📖 Table of Contents

- [What Can Sysmaint Do?](#-what-can-sysmaint-do)
- [Feature Matrix](#-feature-matrix)
- [Quick Examples](#-quick-examples)
- [Test Coverage](#-test-coverage-matrix)
- [Quality Assurance](#-quality-assurance)

---

## 🔗 Quick Links

📥 [Installation Guide](README.md#-installation) • 🗺️ [Release Roadmap](RELEASES.md) • 📦 [Latest Release](https://github.com/Harery/SYSMAINT/releases/latest) • 🐳 [Docker Image](https://github.com/Harery/SYSMAINT/pkgs/container/sysmaint)

---

## 🎯 What Can Sysmaint Do?

Sysmaint is your **all-in-one maintenance toolkit** for Linux systems across multiple distributions (Debian/Ubuntu, Red Hat/Fedora/CentOS/RHEL families). Think of it as having a professional system administrator available 24/7 with multi-distro expertise. **Enterprise Linux validated and production ready.**

### 🔧 At a Glance

| Area | What It Does | Why It Matters |
|:-----|:-------------|:---------------|
| 📦 **Packages** | Updates APT, DNF, Snap, Flatpak | Keep your system secure and up-to-date (Ubuntu, Fedora, CentOS, RHEL) |
| 🧹 **Cleanup** | Removes junk files, old logs, caches | Free up disk space automatically |
| 🔐 **Security** | Audits permissions, detects issues | Protect your system from vulnerabilities |
| 🖥️ **Kernel** | Manages old kernel versions | Prevent `/boot` from filling up |
| 📊 **Reporting** | JSON telemetry, detailed logs | Know exactly what changed |
| ⚡ **Automation** | Unattended mode, scheduled runs | Set it and forget it |

---

## 📋 Feature Matrix

### 📦 Package Management

> Keep your system updated across all package managers

| Feature | Command | Default | What It Does |
|:--------|:--------|:-------:|:-------------|
| 🔄 Update Lists | *(automatic)* | ✅ | Refreshes available package information |
| ⬆️ Upgrade Packages | *(automatic)* | ✅ | Installs available updates safely |
| 🚀 Full Upgrade | `--upgrade` | ❌ | Performs complete distribution upgrade |
| 🗑️ Auto-remove | *(automatic)* | ✅ | Removes packages no longer needed |
| 🧽 Auto-clean | *(automatic)* | ✅ | Cleans downloaded package files |
| 🔑 Fix Missing Keys | `--fix-missing-keys` | ❌ | Installs missing GPG repository keys |

### 📱 Snap & Flatpak

> Modern application format support

| Feature | Command | Default | What It Does |
|:--------|:--------|:-------:|:-------------|
| 🔄 Snap Refresh | *(automatic)* | ✅ | Updates all installed snaps |
| 🗑️ Old Snap Cleanup | `--snap-clean-old` | ❌ | Removes disabled snap versions |
| 🧹 Snap Cache Clear | `--snap-clear-cache` | ❌ | Purges snap download cache |
| ⏭️ Skip Snap | `--no-snap` | ❌ | Disables all snap operations |
| 🔄 Flatpak Update | *(automatic)* | ✅ | Updates flatpak apps if installed |
| 👤 User Flatpaks Only | `--flatpak-user-only` | ❌ | Only updates user-level apps |
| 🖥️ System Flatpaks Only | `--flatpak-system-only` | ❌ | Only updates system-level apps |
| ⏭️ Skip Flatpak | `--no-flatpak` | ❌ | Disables all flatpak operations |

### 🐧 Kernel Management

> Keep your boot partition healthy

| Feature | Command | Default | What It Does |
|:--------|:--------|:-------:|:-------------|
| 🗑️ Purge Old Kernels | `--purge-kernels` | ❌ | Removes outdated kernel packages |
| 📌 Keep N Kernels | `--keep-kernels=N` | 2 | Number of old kernels to preserve |
| 🔧 Update GRUB | `--update-grub` | ❌ | Regenerates bootloader after changes |

### 🧹 Cleanup Operations

> Reclaim disk space and keep things tidy

| Feature | Command | Default | What It Does |
|:--------|:--------|:-------:|:-------------|
| 🗂️ Clear Temp Files | `--clear-tmp` | ✅ | Removes old files from `/tmp` |
| ⚠️ Force Clear Temp | `--clear-tmp-force` | ❌ | Removes ALL temp files (careful!) |
| 📅 Temp Age Limit | `--clear-tmp-age=N` | 1 day | Only remove files older than N days |
| 📜 Journal Vacuum | *(automatic)* | ✅ | Cleans system logs |
| 📆 Journal Days | `--journal-days=N` | 7 | Days of logs to keep |
| 🖼️ Thumbnail Cache | *(automatic)* | ✅ | Clears cached image thumbnails |
| 💥 Crash Dumps | `--clear-crash` | ✅ | Removes crash report files |
| 🌐 DNS Cache | `--clear-dns-cache` | ✅ | Flushes DNS resolver caches |

### 💾 Filesystem Operations

> Advanced storage maintenance

| Feature | Command | Default | What It Does |
|:--------|:--------|:-------:|:-------------|
| ✂️ SSD TRIM | `--fstrim` | ❌ | Optimizes SSD performance |
| 🧠 Drop Caches | `--drop-caches` | ❌ | Frees up memory (page cache) |
| 📦 Orphan Purge | `--orphan-purge` | ❌ | Removes orphaned packages |

### 🌐 Browser Cache

> Manage web browser storage

| Feature | Command | Default | What It Does |
|:--------|:--------|:-------:|:-------------|
| 📊 Cache Report | `--browser-cache-report` | ❌ | Shows Firefox/Chrome cache sizes |
| 🗑️ Cache Purge | `--browser-cache-purge` | ❌ | Deletes browser cache files |

### 🔐 Security & Auditing

> Keep your system secure

| Feature | Command | Default | What It Does |
|:--------|:--------|:-------:|:-------------|
| 🔍 Security Audit | `--security-audit` | ❌ | Checks critical file permissions |
| 👻 Zombie Detection | `--check-zombies` | ✅ | Finds stuck/zombie processes |
| ⚠️ Failed Services | *(automatic)* | ✅ | Detects failed systemd units |
| 🔒 Firmware Updates | *(automatic)* | ✅ | Checks for firmware updates |

### ⚡ Automation & Control

> Run unattended or with full control

| Feature | Command | Default | What It Does |
|:--------|:--------|:-------:|:-------------|
| 👁️ Dry Run | `--dry-run` | ❌ | Preview changes without applying |
| 🤖 Auto Mode | `--auto` | ❌ | Unattended, no prompts |
| 🔄 Auto Reboot | `--auto-reboot` | ❌ | Reboot if system requires |
| ⏱️ Reboot Delay | `--auto-reboot-delay=N` | 30s | Countdown before reboot |
| ✅ Assume Yes | `--yes` | ❌ | Auto-approve all prompts |

### 📊 Output & Telemetry

> Know exactly what happened

| Feature | Command | Default | What It Does |
|:--------|:--------|:-------:|:-------------|
| 📄 JSON Summary | `--json-summary` | ❌ | Outputs detailed JSON report |
| 🎨 Color Mode | `--color=MODE` | auto | `auto`, `always`, or `never` |
| 📈 Progress UI | `--progress=MODE` | none | `spinner`, `dots`, `bar`, `adaptive` |

---

## 🎮 Quick Examples

### 🟢 Beginner: Safe Preview

```bash
# See what would happen without making any changes
./sysmaint --dry-run
```

### 🟡 Intermediate: Weekly Maintenance

```bash
# Standard maintenance with JSON report
sudo ./sysmaint --json-summary
```

### 🔵 Advanced: Full Cleanup

```bash
# Aggressive maintenance for maximum disk recovery
sudo ./sysmaint --upgrade --purge-kernels --orphan-purge --fstrim
```

### 🟣 Expert: Unattended Server

```bash
# Fully automated with controlled reboot
sudo ./sysmaint --auto --auto-reboot-delay 60 --json-summary
```

---

## 🎯 Pre-built Profiles

> One command for common scenarios — no configuration needed!

| Profile | Use Case | Risk Level | Time |
|:--------|:---------|:----------:|:----:|
| 🟢 `minimal` | Safe preview, just telemetry | None | ~2 min |
| 🔵 `standard` | Weekly unattended maintenance | Low | ~5 min |
| 🟡 `desktop` | Desktop cleanup with visuals | Medium | ~6 min |
| 🟠 `server` | Hardened server maintenance | Medium | ~8 min |
| 🔴 `aggressive` | Maximum space reclamation | High | ~10 min |

### 🟢 Minimal Profile

**Best for:** First-time users, testing, read-only audits

```bash
./sysmaint profiles --profile minimal --yes
```

| What It Does | What It Skips |
|:-------------|:--------------|
| ✅ Dry-run mode (no changes) | ❌ Package updates |
| ✅ JSON summary output | ❌ Cleanup operations |
| ✅ System status report | ❌ Kernel management |
| ✅ Zombie process check | ❌ Any destructive actions |

---

### 🔵 Standard Profile

**Best for:** Weekly scheduled maintenance, unattended servers

```bash
sudo ./sysmaint profiles --profile standard --yes
```

| What It Does | What It Skips |
|:-------------|:--------------|
| ✅ APT update & upgrade | ❌ Full distribution upgrade |
| ✅ Snap & Flatpak refresh | ❌ Kernel purging |
| ✅ Journal vacuum (7 days) | ❌ Browser cache |
| ✅ Temp file cleanup | ❌ Orphan purge |
| ✅ Auto-remove unused packages | ❌ SSD TRIM |
| ✅ JSON summary | ❌ Drop caches |

---

### 🟡 Desktop Profile

**Best for:** Personal workstations, laptops, daily drivers

```bash
sudo ./sysmaint profiles --profile desktop --yes
```

| What It Does | What It Skips |
|:-------------|:--------------|
| ✅ Everything in Standard | ❌ Full upgrade |
| ✅ Thumbnail cache cleanup | ❌ Kernel purging |
| ✅ Crash dump removal | ❌ Orphan purge |
| ✅ Browser cache report | ❌ Browser cache purge (opt-in) |
| ✅ Progress spinner UI | ❌ Auto-reboot |
| ✅ Color output | |
| ✅ Desktop session protection | |

---

### 🟠 Server Profile

**Best for:** Production servers, VPS, headless systems

```bash
sudo ./sysmaint profiles --profile server --yes
```

| What It Does | What It Skips |
|:-------------|:--------------|
| ✅ Everything in Standard | ❌ Desktop-specific cleanup |
| ✅ Security audit | ❌ Browser operations |
| ✅ Failed services check | ❌ Thumbnail cache |
| ✅ Zombie process detection | ❌ GUI progress indicators |
| ✅ SSD TRIM (fstrim) | |
| ✅ Firmware update check | |
| ✅ Auto mode (no prompts) | |

---

### 🔴 Aggressive Profile

**Best for:** Disk space recovery, pre-backup cleanup, spring cleaning

⚠️ **Warning:** This profile makes significant changes. Always run with `--dry-run` first!

```bash
# Preview first!
./sysmaint profiles --profile aggressive --print-command

# Then run
sudo ./sysmaint profiles --profile aggressive --yes
```

| What It Does | What It Skips |
|:-------------|:--------------|
| ✅ Full distribution upgrade | ❌ Nothing — full power! |
| ✅ Purge old kernels (keep 2) | |
| ✅ Orphan package removal | |
| ✅ Browser cache purge | |
| ✅ Snap old revisions cleanup | |
| ✅ Snap cache clear | |
| ✅ Force temp cleanup | |
| ✅ SSD TRIM | |
| ✅ Drop page caches | |
| ✅ Journal vacuum (3 days) | |
| ✅ Security audit | |

---

**Usage:**
```bash
# Preview what a profile will do
./sysmaint profiles --profile desktop --print-command

# Run a profile
./sysmaint profiles --profile standard --yes
```

---

## 🧪 Test Coverage Matrix

> Every feature is thoroughly tested

### Test Suites Overview

| Suite | Tests | Type | What It Validates |
|:------|:-----:|:-----|:------------------|
| 🔥 **Smoke Tests** | 65 | Functional | Core features work correctly |
| 🔀 **Edge Cases** | 67 | Boundary | Handles unusual inputs gracefully |
| 🔐 **Security** | 36 | Security | No vulnerabilities or exploits |
| 📋 **Compliance** | 32 | Standards | Meets industry standards |
| 🏛️ **Governance** | 18 | Policy | Code quality and contracts |
| ⚡ **Performance** | ~20 | Benchmark | Speed and efficiency |
| 📄 **JSON Validation** | 4 | Schema | Output format correctness |
| 🔌 **Scanners** | 10 | Integration | External tool integration |
| 🧪 **Sandbox** | 5 | Isolation | Safe testing environment |

### Detailed Breakdown

#### 🔥 Smoke Tests (65 tests)

| Category | Tests | Coverage |
|:---------|:-----:|:---------|
| Basic Operations | 6 | Default run, upgrade, color, zombies, security, browser |
| Filesystem Ops | 3 | fstrim, drop-caches, orphan-purge |
| Kernel Management | 3 | Kernel keep counts, upgrades |
| Journal Config | 3 | Retention periods |
| Browser Cache | 3 | Report and purge operations |
| Snap Management | 3 | Old revision and cache cleanup |
| Temp Cleanup | 3 | Default, disabled, force modes |
| Desktop Guard | 3 | Guard on/off combinations |
| Auto-Reboot | 3 | Delay configurations |
| Advanced Combos | 30 | Multi-flag stress tests |
| Profile Commands | 5 | Subcommand generation |

#### 🔀 Edge Case Tests (67 tests)

| Category | Tests | Coverage |
|:---------|:-----:|:---------|
| Basic Edge | 7 | Help, unknown flags, syntax |
| Empty Values | 5 | Blank arguments handling |
| Long Values | 5 | Extended input strings |
| Special Characters | 5 | Unicode, spaces, symbols |
| Duplicate Flags | 5 | Repeated arguments |
| Multiple Flags | 6 | Complex combinations |
| Flag Order | 5 | Argument ordering |
| Special Shortcuts | 4 | Help, version, dry-only |
| Stress Tests | 4 | Extreme scenarios |
| Extreme Boundaries | 7 | Min/max values |
| Multiple Same Flags | 7 | Repeated identical flags |
| Complex Conflicts | 7 | Conflicting options |
| Complex Ordering | 7 | Mixed argument orders |
| Extreme Stress | 7 | Maximum load tests |

#### 🔐 Security Tests (36 tests)

| Category | Tests | Coverage |
|:---------|:-----:|:---------|
| Permission Audit | 12 | shadow, gshadow, sudoers file checks |
| Input Validation | 8 | Command injection prevention |
| Privilege Checks | 8 | Root/non-root behavior |
| Lockfile Security | 8 | Race conditions, stale locks |

#### 📋 Compliance Tests (32 tests)

| Category | Tests | Coverage |
|:---------|:-----:|:---------|
| CIS Benchmarks | 4 | Center for Internet Security standards |
| FedRAMP | 4 | Federal security requirements |
| NIST 800-53 | 4 | National security controls |
| License Headers | 8 | MIT license, SPDX identifiers |
| Documentation | 12 | README, man page, help text |

#### 🏛️ Governance Tests (18 tests)

| Category | Tests | Coverage |
|:---------|:-----:|:---------|
| Exit Codes | 6 | All 7 documented codes verified |
| Environment | 4 | Variable isolation |
| Logging | 4 | Format and rotation |
| Versioning | 4 | SemVer compliance |

---

## ✅ Quality Assurance

### Overall Statistics

```
╔═══════════════════════════════════════════════════════════╗
║                    QUALITY DASHBOARD                       ║
╠═══════════════════════════════════════════════════════════╣
║  ✅ Total Tests          │  246 passing                   ║
║  ✅ Test Coverage        │  100%                          ║
║  ✅ ShellCheck Errors    │  0                             ║
║  ✅ ShellCheck Warnings  │  0                             ║
║  ✅ License Compliance   │  MIT (all files)               ║
║  ✅ Documentation        │  Complete                      ║
╚═══════════════════════════════════════════════════════════╝
```

### Exit Codes Reference

| Code | Meaning | Action Required |
|:----:|:--------|:----------------|
| `0` | ✅ Success | None - all good! |
| `1` | ❌ General Error | Check logs for details |
| `2` | ❌ Invalid Arguments | Review command syntax |
| `10` | ⚠️ Repository Issues | Check APT sources |
| `20` | ⚠️ Missing Keys | Run with `--fix-missing-keys` |
| `30` | ⚠️ Failed Services | Review systemd status |
| `75` | 🔒 Lock Timeout | Another instance running |
| `100` | 🔄 Reboot Required | Restart system when ready |

> 💡 **Tip:** Exit codes `0` and `100` both indicate successful completion!

---

## 🎓 Learning Path

### For Beginners

1. **Start Safe**: Always use `--dry-run` first
2. **Read Output**: Check what will happen before committing
3. **Use Profiles**: Pre-built profiles are tested and safe
4. **Check Logs**: Find detailed logs in `/tmp/system-maintenance/`

### For Advanced Users

1. **Customize**: Combine flags for your specific needs
2. **Automate**: Set up systemd timers for scheduled runs
3. **Monitor**: Use `--json-summary` for integration with monitoring tools
4. **Secure**: Enable `--security-audit` for hardened systems

---

## 📚 More Resources

| Resource | Description |
|:---------|:------------|
| [README.md](README.md) | Quick start and usage |
| [CHANGELOG.md](CHANGELOG.md) | Version history |
| [docs/SECURITY.md](docs/SECURITY.md) | Security guidelines |
| [docs/PERFORMANCE.md](docs/PERFORMANCE.md) | Benchmarks |

---

<div align="center">

## 👨‍💻 Author

**Mohamed Elharery**

[![Website](https://img.shields.io/badge/Website-www.harery.com-blue?style=flat-square)](https://www.harery.com)
[![Email](https://img.shields.io/badge/Email-Mohamed%40Harery.com-red?style=flat-square)](mailto:Mohamed@Harery.com)
[![GitHub](https://img.shields.io/badge/GitHub-Harery-black?style=flat-square&logo=github)](https://github.com/Harery)

---

**MIT Licensed** • **Production Ready** • **Safe to Run Dry-First**

[⬆️ Back to Top](#-sysmaint-feature-matrix)

</div>
