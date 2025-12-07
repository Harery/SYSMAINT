# 🛠️ sysmaint

<div align="center">

![Version](https://img.shields.io/badge/version-2.2.0-blue.svg)
[![Release](https://img.shields.io/github/v/release/Harery/SYSMAINT?label=release&color=green)](https://github.com/Harery/SYSMAINT/releases/latest)
[![Docker](https://img.shields.io/badge/docker-ghcr.io-blue?logo=docker)](https://github.com/Harery/SYSMAINT/pkgs/container/sysmaint)
[![CI](https://github.com/Harery/SYSMAINT/actions/workflows/ci.yml/badge.svg)](https://github.com/Harery/SYSMAINT/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/tests-246%20passing-brightgreen)](https://github.com/Harery/SYSMAINT)
[![Coverage](https://img.shields.io/badge/coverage-100%25-brightgreen)](https://github.com/Harery/SYSMAINT)
[![Architecture](https://img.shields.io/badge/architecture-modular-purple.svg)](https://github.com/Harery/SYSMAINT)

**A safe, scriptable multi-distro maintenance automation toolkit with modular architecture**

*APT + Snap updates • Cleanup phases • JSON telemetry • Unattended mode • Security audits*

[Features](FEATURES.md) • [Releases](RELEASES.md) • [Changelog](CHANGELOG.md) • [Security](docs/SECURITY.md) • [Performance](docs/PERFORMANCE.md)

</div>

---

## ✨ Highlights

| Feature | Description |
|:--------|:------------|
| 📦 **Package Updates** | APT, Snap, Flatpak — all in one run |
| 🧹 **Smart Cleanup** | Temp files, logs, caches, old kernels |
| 🔐 **Security Audit** | Permission checks, zombie detection |
| 📊 **JSON Telemetry** | Detailed reports for monitoring integration |
| 🤖 **Automation Ready** | Systemd timers, unattended mode |
| ✅ **Production Tested** | 246 tests, 100% coverage |

---

## 📥 Installation

### Option 1: Download .deb Package (Recommended)

```bash
# Download the latest release
wget https://github.com/Harery/SYSMAINT/releases/download/v2.2.0/sysmaint_2.2.0_all.deb

# Install
sudo dpkg -i sysmaint_2.2.0_all.deb

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
  "script_version": "2.2.0",
  "run_id": "2025-12-06_120000_12345",
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

## 📚 Documentation

| Document | Purpose |
|:---------|:--------|
| 📋 [FEATURES.md](FEATURES.md) | Complete capability matrix |
| 🗺️ [RELEASES.md](RELEASES.md) | Release roadmap and future plans |
| 📝 [CHANGELOG.md](CHANGELOG.md) | Version history |
| 🔐 [docs/SECURITY.md](docs/SECURITY.md) | Security guidelines |
| ⚡ [docs/PERFORMANCE.md](docs/PERFORMANCE.md) | Benchmarks |

---

## 🏗️ Architecture (v2.2.0)

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

## 🗺️ Roadmap

| Version | Target | Focus |
|---------|:------:|:------|
| **v2.2.0** | ✅ Dec 2025 | 🏗️ Modular architecture + multi-distro foundation |
| **v2.3.0** | Q1 2026 | 🐧 Full RHEL/Fedora/Arch/SUSE support |
| **v3.0.0** | Q3-Q4 2026 | 🖥️ Dual-mode: CLI + Interactive GUI |

📖 [View detailed roadmap](RELEASES.md) with implementation phases and technical specifications

---

## 💻 Requirements

- **OS:** Ubuntu 20.04+ or Debian 10+
- **Shell:** Bash 4.0+
- **Privileges:** Root for system changes (dry-run works without)

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
