<div align="center">

# 🛠️ SYSMAINT

### Enterprise Linux System Maintenance — One Command, All Distros

[![Release](https://img.shields.io/github/v/release/Harery/SYSMAINT?style=for-the-badge&logo=github)](https://github.com/Harery/SYSMAINT/releases/latest)
[![License](https://img.shields.io/github/license/Harery/SYSMAINT?style=for-the-badge&color=blue)](LICENSE)
[![Docker](https://img.shields.io/badge/docker-ready-blue?style=for-the-badge&logo=docker)](https://ghcr.io/harery/sysmaint)
[![Tests](https://img.shields.io/badge/tests-500%2B-success?style=for-the-badge&logo=github)](tests)

[![Stars](https://img.shields.io/github/stars/Harery/SYSMAINT?style=social)](https://github.com/Harery/SYSMAINT/stargazers)
[![Forks](https://img.shields.io/github/forks/Harery/SYSMAINT?style=social)](https://github.com/Harery/SYSMAINT/network/members)

**Automated Package Updates • System Cleanup • Security Auditing • Performance Optimization**

Supports **Ubuntu, Debian, Fedora, RHEL, Rocky, Alma, CentOS, Arch, openSUSE**

</div>

---

## 📖 Table of Contents

- [Quick Start](#-quick-start)
- [Why SYSMAINT](#-why-sysmaint)
- [Features](#-features)
- [Platform Support](#-platform-support)
- [Installation](#-installation)
- [Usage](#-usage)
- [Automation](#-automation)
- [Documentation](#-documentation)
- [Quality Metrics](#-quality-metrics)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/Harery/SYSMAINT.git
cd SYSMAINT

# Make executable
chmod +x sysmaint

# Preview changes (100% safe, read-only)
sudo ./sysmaint --dry-run

# Execute maintenance
sudo ./sysmaint
```

**Or use Docker:**
```bash
docker run --rm --privileged ghcr.io/harery/sysmaint:latest
```

---

## ✨ Why SYSMAINT?

Linux system maintenance is fragmented across distributions, each with different package managers, cleanup procedures, and security practices. SYSMAINT unifies这一切 into a single, production-ready tool.

| Feature | SYSMAINT | Traditional Scripts |
|:-------:|:--------:|:-------------------:|
| **9 Distros** | ✅ One tool | ❌ Multiple scripts |
| **Safety** | ✅ Dry-run mode | ❌ Risky execution |
| **Audit Trail** | ✅ JSON output | ❌ No logging |
| **Interactive** | ✅ TUI menu | ❌ CLI only |
| **Tests** | ✅ 500+ tests | ❌ None |
| **Speed** | ⚡ <3.5 min avg | 🐌 Variable |

---

## 📦 Features

### Core Capabilities

```mermaid
graph LR
    A[sysmaint] --> B[Package Management]
    A --> C[System Cleanup]
    A --> D[Security Auditing]
    A --> E[Performance Optimization]

    B --> B1[apt/dnf/pacman/zypper]
    B --> B2[snap packages]
    B --> B3[flatpak packages]

    C --> C1[Log rotation]
    C --> C2[Cache cleanup]
    C --> C3[Old kernel removal]

    D --> D1[SSH configuration]
    D --> D2[Firewall status]
    D --> D3[Service validation]

    E --> E1[Disk recovery reporting]
    E --> E2[JSON telemetry]
```

### What SYSMAINT Does

| Module | Description | Benefit |
|--------|-------------|---------|
| **Package Management** | Automated updates, upgrades, and cleanup | Keeps software current & secure |
| **System Cleanup** | Removes logs, caches, temp files, old kernels | Recovers disk space |
| **Security Auditing** | Checks permissions, services, and repos | Identifies vulnerabilities |
| **JSON Telemetry** | Structured output for monitoring | Enables automation |
| **Dry-Run Mode** | Preview all changes safely | Zero-risk testing |
| **Interactive TUI** | User-friendly dialog-based menu | Easy for beginners |

---

## 🌍 Platform Support

| Distribution | Versions | Package Manager | Status |
|--------------|----------|:---------------:|:------:|
| **Ubuntu** | 22.04, 24.04 | `apt` | ✅ LTS |
| **Debian** | 12, 13 | `apt` | ✅ Stable |
| **Fedora** | 41 | `dnf` | ✅ Latest |
| **RHEL** | 9, 10 | `dnf/yum` | ✅ Enterprise |
| **Rocky Linux** | 9, 10 | `dnf/yum` | ✅ Enterprise |
| **AlmaLinux** | 9, 10 | `dnf/yum` | ✅ Enterprise |
| **CentOS** | 9 Stream | `dnf/yum` | ✅ Stream |
| **Arch Linux** | Rolling | `pacman` | ✅ Tested |
| **openSUSE** | Tumbleweed | `zypper` | ✅ Tested |

---

## 📥 Installation

### Method 1: Git Clone (Recommended)

```bash
git clone https://github.com/Harery/SYSMAINT.git
cd SYSMAINT
chmod +x sysmaint
sudo ./sysmaint --dry-run
```

### Method 2: Direct Download

```bash
curl -O https://raw.githubusercontent.com/Harery/SYSMAINT/main/sysmaint
chmod +x sysmaint
sudo ./sysmaint --dry-run
```

### Method 3: Docker

```bash
docker pull ghcr.io/harery/sysmaint:latest
docker run --rm --privileged ghcr.io/harery/sysmaint:latest
```

### Method 4: System-Wide Installation

```bash
# Install to system path
sudo install -Dm755 sysmaint /usr/local/sbin/sysmaint

# Enable automated maintenance
sudo install -Dm644 packaging/systemd/sysmaint.{service,timer} /etc/systemd/system/
sudo systemctl enable --now sysmaint.timer
```

> **📖 Full Installation Guide:** [docs/INSTALLATION.md](docs/INSTALLATION.md)

---

## 💻 Usage

### Interactive Mode (Recommended for First-Time Users)

```bash
sudo ./sysmaint --gui
```

Launches an interactive terminal menu (TUI) for guided operation.

### Fully Automated Mode

```bash
sudo ./sysmaint --auto
```

Runs all maintenance operations without prompts.

### Specific Operations

```bash
# Package management only
sudo ./sysmaint --upgrade

# Cleanup only
sudo ./sysmaint --cleanup

# Remove old kernels
sudo ./sysmaint --purge-kernels

# Security audit only
sudo ./sysmaint --security-audit
```

### JSON Output for Automation

```bash
sudo ./sysmaint --json-summary | jq .
```

### Quiet Mode (for Cron)

```bash
sudo ./sysmaint --auto --quiet
```

### All Command-Line Options

| Option | Description |
|--------|-------------|
| `--dry-run` | Preview changes without executing |
| `--gui` | Interactive TUI menu |
| `--auto` | Non-interactive automated mode |
| `--upgrade` | Update all packages |
| `--cleanup` | Clean caches and temp files |
| `--purge-kernels` | Remove old kernel packages |
| `--security-audit` | Run security checks |
| `--json-summary` | Output results in JSON format |
| `--verbose` | Detailed logging output |
| `--quiet` | Minimal output only |

---

## 🤖 Automation

### Systemd Timer (Recommended)

```bash
# Install service files
sudo install -Dm755 sysmaint /usr/local/sbin/sysmaint
sudo install -Dm644 packaging/systemd/sysmaint.{service,timer} /etc/systemd/system/

# Enable weekly automatic maintenance
sudo systemctl enable --now sysmaint.timer

# Check status
sudo systemctl status sysmaint.timer
```

### Cron Job

```bash
# Edit crontab
crontab -e

# Add weekly maintenance (Sundays at 2 AM)
0 2 * * 0 /usr/local/sbin/sysmaint --auto --quiet
```

### Docker Compose

```yaml
services:
  sysmaint:
    image: ghcr.io/harery/sysmaint:latest
    privileged: true
    volumes:
      - /:/host:ro
    # Override command as needed
    # command: ["--auto", "--quiet"]
```

### Kubernetes CronJob

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: sysmaint
spec:
  schedule: "0 2 * * 0"  # Weekly at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: sysmaint
            image: ghcr.io/harery/sysmaint:latest
            securityContext:
              privileged: true
          restartPolicy: OnFailure
```

---

## 📊 Quality Metrics

| Metric | Value | Status |
|--------|-------|:------:|
| **Test Coverage** | 500+ tests across 14 suites | ✅ |
| **Code Quality** | ShellCheck: 0 errors | ✅ |
| **Runtime** | <3.5 minutes average | ✅ |
| **Memory Usage** | <50 MB | ✅ |
| **Platform Support** | 9 distributions tested | ✅ |
| **Container Images** | Multi-arch (amd64/arm64) | ✅ |

---

## 🔒 Security

SYSMAINT is built with security-first principles:

- ✅ **Input Validation** — All parameters sanitized
- ✅ **Least Privilege** — Minimal sudo requirements
- ✅ **Audit Trail** — JSON output for compliance
- ✅ **No External Calls** — Zero network dependencies
- ✅ **ShellCheck Verified** — Static analysis passed
- ✅ **Vulnerability Scanning** — CI/CD integrated

> **🔐 Security Policy:** [docs/SECURITY.md](docs/SECURITY.md)

---

## 📖 Documentation

| Document | Description |
|----------|-------------|
| **[Product Requirements (PRD)](docs/PRD.md)** | Product vision, requirements & roadmap |
| **[Project Structure](docs/PROJECT_STRUCTURE.md)** | Directory organization & file layout |
| **[Installation Guide](docs/INSTALLATION.md)** | All installation methods |
| **[Troubleshooting](docs/TROUBLESHOOTING.md)** | Common issues & solutions |
| **[Architecture](docs/ARCHITECTURE.md)** | System design & components |
| **[Performance](docs/PERFORMANCE.md)** | Benchmarks by OS |
| **[Security](docs/SECURITY.md)** | Security policy & best practices |
| **[Contributing](docs/CONTRIBUTING.md)** | Development guidelines |
| **[Code of Conduct](docs/CODE_OF_CONDUCT.md)** | Community guidelines |

---

## 🤝 Contributing

We welcome contributions from the community! Please see our contributing guidelines:

- **[Contributing Guide](docs/CONTRIBUTING.md)** — Development workflow & standards
- **[Code of Conduct](docs/CODE_OF_CONDUCT.md)** — Community guidelines

---

## 📜 License

MIT © 2025 [Mohamed Elharery](https://www.harery.com)

> **Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:**
>
> **The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.**

---

## ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=Harery/SYSMAINT&type=Date)](https://star-history.com/#Harery/SYSMAINT&Date)

**If you find SYSMAINT useful, please consider giving it a star! ⭐**

---

## 🔗 Quick Links

| Resource | Link |
|----------|------|
| **Website** | https://www.harery.com |
| **Repository** | https://github.com/Harery/SYSMAINT |
| **Documentation** | https://github.com/Harery/SYSMAINT/tree/main/docs |
| **Issue Tracker** | https://github.com/Harery/SYSMAINT/issues |
| **Discussions** | https://github.com/Harery/SYSMAINT/discussions |
| **Releases** | https://github.com/Harery/SYSMAINT/releases |
| **Docker Image** | https://ghcr.io/harery/sysmaint |

---

<div align="center">

**Built with ❤️ for the Linux ecosystem**

*[GitHub](https://github.com/Harery/SYSMAINT) • [Documentation](docs/) • [Support](https://github.com/Harery/SYSMAINT/issues) • [Discussions](https://github.com/Harery/SYSMAINT/discussions)*

</div>
