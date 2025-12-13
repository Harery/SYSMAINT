# 🛠️ sysmaint

<div align="center">

![Version](https://img.shields.io/badge/version-2.2.1-blue.svg)
[![Release](https://img.shields.io/github/v/release/Harery/SYSMAINT?label=release&color=green)](https://github.com/Harery/SYSMAINT/releases/latest)
[![Docker](https://img.shields.io/badge/docker-ghcr.io-blue?logo=docker)](https://github.com/Harery/SYSMAINT/pkgs/container/sysmaint)
[![CI](https://github.com/Harery/SYSMAINT/actions/workflows/ci.yml/badge.svg)](https://github.com/Harery/SYSMAINT/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/tests-281%20passing-brightgreen)](https://github.com/Harery/SYSMAINT)
[![Coverage](https://img.shields.io/badge/coverage-100%25-brightgreen)](https://github.com/Harery/SYSMAINT)
[![CI Jobs](https://img.shields.io/badge/CI%20jobs-4%20distros-blue)](https://github.com/Harery/SYSMAINT/actions)
[![Architecture](https://img.shields.io/badge/architecture-modular-purple.svg)](https://github.com/Harery/SYSMAINT)
[![Enterprise](https://img.shields.io/badge/RHEL-validated-red.svg)](https://github.com/Harery/SYSMAINT)

**A safe, scriptable multi-distro maintenance automation toolkit with modular architecture**

*APT + Snap updates • Cleanup phases • JSON telemetry • Unattended mode • Security audits*

[Features](FEATURES.md) • [Releases](RELEASES.md) • [Changelog](CHANGELOG.md) • [Security](docs/SECURITY.md) • [Performance](docs/PERFORMANCE.md)

</div>

---

## ✨ Highlights

| Feature | Description |
|:--------|:------------|
| 🏗️ **Modular Architecture** | 21 specialized modules across 6 categories for maintainability |
| 🐧 **Multi-Distro Validated** | Ubuntu, Fedora, CentOS, RHEL — 100% test success on all |
| 📦 **Universal Updates** | APT, DNF, Pacman, Snap, Flatpak — unified interface |
| 🧹 **Smart Cleanup** | Intelligent cleanup across temp files, logs, caches, old kernels |
| 🔐 **Security Hardening** | Built-in audits, permission checks, vulnerability scanning |
| 📊 **Rich Telemetry** | Structured JSON output with schema validation |
| 🤖 **Full Automation** | Systemd timers, unattended mode, CI/CD integration |
| ✅ **Battle Tested** | 281 tests, 100% coverage, enterprise production-proven |

---

## 📥 Installation

### Option 1: Download .deb Package (Recommended)

```bash
# Download the latest release
wget https://github.com/Harery/SYSMAINT/releases/download/v2.2.1/sysmaint_2.2.1-1_all.deb

# Install
sudo dpkg -i sysmaint_2.2.1-1_all.deb

# Run
sudo sysmaint --help
```

### Option 2: Docker

```bash
# Pull the image
docker pull ghcr.io/harery/sysmaint:latest

# Run
docker run --rm ghcr.io/harery/sysmaint --help

# Dry-run with JSON output
docker run --rm ghcr.io/harery/sysmaint --dry-run --json-summary
```

### Option 3: Clone Repository

```bash
git clone https://github.com/Harery/SYSMAINT.git
cd SYSMAINT
chmod +x sysmaint
./sysmaint --help
```

---

## 🚀 Quick Start

### 👁️ Safe Preview (Recommended First Run)

```bash
# See what would happen without making changes
./sysmaint --dry-run --json-summary
```

### ⚡ Standard Maintenance

```bash
# Weekly maintenance with JSON report
sudo ./sysmaint --json-summary
```

### 🤖 Unattended Mode

```bash
# Fully automated with controlled reboot
sudo ./sysmaint --auto --auto-reboot-delay 45 --json-summary
```

### 🚀 Full Upgrade

```bash
# Include distribution upgrade phase
sudo ./sysmaint --upgrade --json-summary
```

---

## 📋 Common Flags

> 📖 **See [FEATURES.md](FEATURES.md) for the complete flag reference and pre-built profiles**

### ⬆️ Updates & Upgrades

| Flag | Description |
|:-----|:------------|
| `--upgrade` | Perform full distribution upgrade |
| `--no-snap` | Skip Snap operations |
| `--no-flatpak` | Skip Flatpak operations |
| `--no-firmware` | Skip firmware updates |

### 🧹 Cleanup Operations

| Flag | Description |
|:-----|:------------|
| `--purge-kernels` | Remove old kernel packages |
| `--keep-kernels=N` | Keep N old kernels (default: 2) |
| `--orphan-purge` | Remove orphaned packages |
| `--fstrim` | Run SSD TRIM |
| `--drop-caches` | Clear page cache |
| `--journal-days=N` | Keep N days of logs |

### 🔐 Security

| Flag | Description |
|:-----|:------------|
| `--security-audit` | Check critical file permissions |
| `--check-zombies` | Detect zombie processes |

### 🌐 Browser Cache

| Flag | Description |
|:-----|:------------|
| `--browser-cache-report` | Show Firefox/Chrome cache sizes |
| `--browser-cache-purge` | Delete browser caches |

### ⚡ Automation

| Flag | Description |
|:-----|:------------|
| `--dry-run` | Preview without changes |
| `--auto` | Unattended mode (no prompts) |
| `--auto-reboot` | Reboot if required |
| `--auto-reboot-delay=N` | Wait N seconds before reboot |
| `--yes` | Auto-approve prompts |

### 📊 Output

| Flag | Description |
|:-----|:------------|
| `--json-summary` | Generate JSON report |
| `--color=MODE` | `auto`, `always`, or `never` |
| `--progress=MODE` | `spinner`, `dots`, `bar`, `adaptive` |

> 💡 **Tip:** Disable any default with `--no-*` (e.g., `--no-clear-tmp`, `--no-journal-vacuum`)

---

## 📄 JSON Telemetry

Enable with `--json-summary` to get detailed reports in `/tmp/system-maintenance/`:

```json
{
  "script_version": "2.2.1",
  "run_id": "2025-12-12_120000_12345",
  "exit_code": 0,
  "phases": { ... },
  "disk_delta": { ... },
  "security_audit": { ... }
}
```

**Schema:** `docs/schema/sysmaint-summary.schema.json`

---

## ⏰ Systemd Timer (Automated Weekly)

```bash
# Install sysmaint
sudo install -Dm755 sysmaint /usr/local/sbin/sysmaint

# Install systemd units
sudo install -Dm644 packaging/systemd/sysmaint.service /etc/systemd/system/
sudo install -Dm644 packaging/systemd/sysmaint.timer /etc/systemd/system/

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable --now sysmaint.timer
```

**Optional:** Create `/etc/sysmaint/sysmaint.env` for custom settings.

---

## 🔐 Security Scanners

### Built-in Audit

```bash
# Check shadow, gshadow, sudoers permissions
sudo ./sysmaint --security-audit
```

### External Scanners (Lynis + rkhunter)

```bash
# Run with threshold enforcement
LYNIS_MIN_SCORE=80 RKHUNTER_MAX_WARNINGS=5 ./sysmaint scanners
```

See [docs/SECURITY.md](docs/SECURITY.md) for details.

---

## 💡 Real-World Examples

### Weekly Maintenance Automation

```bash
# Add to crontab for weekly Sunday 2 AM maintenance
0 2 * * 0 /usr/local/sbin/sysmaint --auto --json-summary >> /var/log/sysmaint-weekly.log 2>&1
```

### Server Deployment Pipeline

```bash
# Post-deployment maintenance (in CI/CD)
sudo sysmaint --dry-run --json-summary                    # Verify system state
sudo sysmaint --update-packages --clear-tmp --auto       # Clean and update
sudo sysmaint --reboot-if-required --auto-reboot-delay 60 # Reboot if needed
```

### Desktop Workstation (Interactive)

```bash
# Morning routine - check before updates
sudo sysmaint --dry-run --json-summary

# Apply updates with review
sudo sysmaint --update-packages

# Full cleanup on demand
sudo sysmaint --clear-caches --vacuum-journal --remove-old-kernels
```

### Container/VM Maintenance

```bash
# Minimal maintenance for containers
docker run --rm --privileged -v /:/host \
  ghcr.io/harery/sysmaint \
  --update-packages --clear-tmp --no-reboot

# VM snapshot before maintenance
virsh snapshot-create-as myvm pre-maintenance
sudo sysmaint --auto --json-summary
```

### Emergency Recovery

```bash
# Free up space quickly (when /boot is full)
sudo sysmaint --remove-old-kernels --clear-tmp --auto

# Fix broken packages
sudo sysmaint --fix-broken-packages --auto

# Audit after compromise
sudo sysmaint --security-audit --json-summary
```

---

## 🔧 Troubleshooting

### Common Issues

**Issue: "User must be root"**
```bash
# Solution: Run with sudo
sudo sysmaint --dry-run
```

**Issue: "/boot is full, cannot install kernels"**
```bash
# Solution: Remove old kernels first
sudo sysmaint --remove-old-kernels --auto
sudo apt-get autoremove  # Or: sudo dnf autoremove
```

**Issue: "Lock file exists"**
```bash
# Solution: Remove stale lock (ensure no other instance running)
sudo rm -f /tmp/sysmaint.lock /run/sysmaint.lock
```

**Issue: "JSON validation failed"**
```bash
# Solution: Check JSON output manually
sudo sysmaint --json-summary
cat /tmp/system-maintenance/summary_*.json | jq .
```

**Issue: "Package manager locked"**
```bash
# Solution: Wait for other package operations or kill if stuck
# Ubuntu/Debian:
sudo killall apt apt-get dpkg
sudo rm /var/lib/dpkg/lock-frontend /var/lib/apt/lists/lock
# Fedora/RHEL/Rocky/Alma:
sudo killall dnf yum
sudo rm /var/cache/dnf/*/download_lock.pid
```

### Performance Tips

```bash
# Speed up by skipping slow operations
sysmaint --no-vacuum-journal --no-clear-caches

# Parallel execution (faster on multi-core)
sysmaint --parallel-jobs 4

# Benchmark specific operations
time sysmaint --update-packages --dry-run
```

### Debugging

```bash
# Enable verbose output
sudo bash -x sysmaint --dry-run

# Check what would change without modifying
sudo sysmaint --dry-run --json-summary

# Validate JSON schema
python3 tests/validate_json.py /tmp/system-maintenance/summary_*.json
```

---

## 📚 Documentation

### User Documentation

| Document | Purpose |
|:---------|:--------|
| 📋 [FEATURES.md](FEATURES.md) | Complete feature matrix with 12 pre-built profiles |
| 🗺️ [RELEASES.md](RELEASES.md) | Release roadmap and version timeline |
| 📝 [CHANGELOG.md](CHANGELOG.md) | Detailed version history and changes |

### Technical Documentation

| Document | Purpose |
|:---------|:--------|
| 🏗️ [lib/core/README.md](lib/core/README.md) | Module architecture and organization |
| 🔐 [docs/SECURITY.md](docs/SECURITY.md) | Security audits, best practices, scanner integration |
| ⚡ [docs/PERFORMANCE.md](docs/PERFORMANCE.md) | Benchmarks, baselines, performance tracking |
| 📊 [docs/schema/](docs/schema/) | JSON telemetry schema specifications |

### Developer Resources

| Resource | Purpose |
|:---------|:--------|
| 🧪 [tests/README.md](tests/README.md) | Test suite documentation (281 tests) |
| 🔧 [.github/](.github/) | Issue templates and contribution guidelines |
| 📦 [packaging/](packaging/) | Distribution packaging (DEB, RPM, systemd units) |

---

## 🏗️ Architecture (v2.2.1)

sysmaint uses a **modern modular architecture** for improved maintainability and extensibility:

```
lib/
├── core/          Foundation (init, logging, error handling)
├── progress/      UI, timing, parallel execution
├── maintenance/   Package management, system cleanup
├── validation/    Health checks, security audits
├── reporting/     Summary generation, output formatting
└── os_families/   Distribution-specific implementations
```

**Benefits:**
- ✅ **21 specialized modules** across 6 categories
- ✅ **69 functions** organized by purpose
- ✅ **Per-module testing** for better quality
- ✅ **Multi-distro support** via OS family abstraction
- ✅ **Easy collaboration** with clear ownership

---

## 💻 Requirements

- **OS:** Linux (Multi-distro support: Debian/Ubuntu & Red Hat/Fedora/CentOS validated)
- **Shell:** Bash 4.0+
- **Privileges:** Root for system changes (dry-run works without)

**Supported Distributions (v2.2.1):**

*CI-Tested Platforms (100% test success):*
- ✅ Ubuntu 24.04 LTS (260/260 tests passing)
- ✅ Fedora 43 (260/260 tests passing)
- ✅ CentOS Stream 10 (260/260 tests passing)
- ✅ RHEL 10 (281/281 tests passing, includes 21 combo tests)

*Compatible (Uses Red Hat Family Code, Untested in CI):*
- 🟡 Rocky Linux 9/10 (Should work, not validated)
- 🟡 AlmaLinux 9/10 (Should work, not validated)

*Foundation Ready (Planned for v2.3.0):*
- 🚧 Arch/Manjaro (OS detection ready, full validation pending)
- 🚧 openSUSE/SUSE (OS detection ready, full validation pending)
- 🚧 Debian 12+ (APT family, not yet tested)

---

## 🤝 Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch
3. Run tests: `bash tests/test_suite_smoke.sh`
4. Submit a pull request

See our [Issue Templates](.github/ISSUE_TEMPLATE/) for bug reports and feature requests.

---

<div align="center">

## 👨‍💻 Author

**Mohamed Elharery**

[![Website](https://img.shields.io/badge/Website-www.harery.com-blue?style=flat-square)](https://www.harery.com)
[![Email](https://img.shields.io/badge/Email-Mohamed%40Harery.com-red?style=flat-square)](mailto:Mohamed@Harery.com)
[![GitHub](https://img.shields.io/badge/GitHub-Harery-black?style=flat-square&logo=github)](https://github.com/Harery)

---

**MIT Licensed** • **Production Ready** • **Safe to Run Dry-First**

[⬆️ Back to Top](#️-sysmaint)

</div>
