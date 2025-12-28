<div align="center">

# 🛠️ SYSMAINT

**Enterprise Linux System Maintenance — One command, all distros**

[![Release](https://img.shields.io/github/v/release/Harery/SYSMAINT?style=for-the-badge&logo=github)](https://github.com/Harery/SYSMAINT/releases/latest)
[![License](https://img.shields.io/github/license/Harery/SYSMAINT?style=for-the-badge&color=blue)](LICENSE)
[![Docker](https://img.shields.io/badge/docker-ready-blue?style=for-the-badge&logo=docker)](https://ghcr.io/harery/sysmaint)

[![Stars](https://img.shields.io/github/stars/Harery/SYSMAINT?style=social)](https://github.com/Harery/SYSMAINT/stargazers)
[![Forks](https://img.shields.io/github/forks/Harery/SYSMAINT?style=social)](https://github.com/Harery/SYSMAINT/network/members)

**Automated package updates • System cleanup • Security auditing • Performance optimization**

Supports **Ubuntu, Debian, Fedora, RHEL, Rocky, Alma, CentOS, Arch, openSUSE**

</div>

---

## 🚀 Quick Start

```bash
git clone https://github.com/Harery/SYSMAINT.git
cd SYSMAINT
chmod +x sysmaint

# Preview (100% safe)
sudo ./sysmaint --dry-run

# Run maintenance
sudo ./sysmaint
```

**Or use Docker:**
```bash
docker run --rm --privileged ghcr.io/harery/sysmaint:latest
```

---

## ✨ Why SYSMAINT?

| Feature | SYSMAINT | Traditional Scripts |
|---------|----------|-------------------|
| **9 Distros** | ✅ One tool | ❌ Multiple scripts |
| **Safety** | ✅ Dry-run mode | ❌ Risky |
| **Audit Trail** | ✅ JSON output | ❌ None |
| **Interactive** | ✅ TUI menu | ❌ CLI only |
| **Tests** | ✅ 500+ tests | ❌ None |
| **Speed** | ⚡ <3.5s avg | 🐌 Variable |

---

## 📦 What It Does

```bash
# One command handles everything:
├── 🔄 Package updates (apt/dnf/pacman/zypper + snap/flatpak)
├── 🧹 System cleanup (caches, temp files, old kernels)
├── 🔒 Security audit (permissions, services, repos)
├── 📊 JSON telemetry (for monitoring/CI/CD)
└── ⚡ Performance optimization
```

---

## 🌍 Platform Support

| Distro | Versions | Status |
|--------|----------|--------|
| Ubuntu | 22.04, 24.04 | ✅ LTS |
| Debian | 12, 13 | ✅ Stable |
| Fedora | 41 | ✅ Latest |
| RHEL/Rocky/Alma | 9, 10 | ✅ Enterprise |
| Arch | Rolling | ✅ Tested |
| openSUSE | Tumbleweed | ✅ Tested |

---

## 💻 Usage

```bash
# Interactive menu (recommended for first-time users)
sudo ./sysmaint --gui

# Full automated mode
sudo ./sysmaint --auto

# Specific operations
sudo ./sysmaint --upgrade --purge-kernels --security-audit

# JSON output for automation
sudo ./sysmaint --json-summary | jq .

# Quiet mode for cron
sudo ./sysmaint --auto --quiet
```

### Full Options
| Option | Description |
|--------|-------------|
| `--dry-run` | Preview without changes |
| `--gui` | Interactive TUI menu |
| `--auto` | Non-interactive mode |
| `--upgrade` | Update all packages |
| `--cleanup` | Clean caches and temp |
| `--purge-kernels` | Remove old kernels |
| `--security-audit` | Run security checks |
| `--json-summary` | JSON output |
| `--verbose` | Detailed logging |
| `--quiet` | Minimal output |

---

## 🤖 Automation

**Systemd Timer:**
```bash
sudo install -Dm755 sysmaint /usr/local/sbin/sysmaint
sudo install -Dm644 packaging/systemd/sysmaint.{service,timer} /etc/systemd/system/
sudo systemctl enable --now sysmaint.timer
```

**Cron:**
```bash
0 2 * * 0 /usr/local/sbin/sysmaint --auto --quiet
```

**Docker Compose:**
```yaml
services:
  sysmaint:
    image: ghcr.io/harery/sysmaint:latest
    privileged: true
    volumes:
      - /:/host:ro
```

---

## 📊 Quality Metrics

| Metric | Value |
|--------|-------|
| Tests | 500+ across 14 suites |
| Coverage | 100% |
| ShellCheck | 0 errors |
| Runtime | <3.5s average |
| Memory | <50MB |
| Platforms | 9 distros validated |

---

## 🔒 Security

✅ Input validation • ✅ Least privilege • ✅ Audit trail • ✅ Vulnerability scanning • ✅ ShellCheck passed

---

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [Full Documentation](docs/) | Complete guide |
| [Installation Guide](docs/INSTALLATION.md) | All installation methods |
| [Troubleshooting](docs/TROUBLESHOOTING.md) | Common issues |
| [Architecture](docs/ARCHITECTURE.md) | Code structure |
| [Performance](docs/PERFORMANCE.md) | Benchmarks by OS |
| [Security](docs/SECURITY.md) | Security policy |
| [Contributing](CONTRIBUTING.md) | Dev guidelines |
| [Release Notes](RELEASE_NOTES_v1.0.0.md) | v1.0.0 details |

---

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md).

---

## 📜 License

MIT © 2025 Mohamed Elharery

---

## ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=Harery/SYSMAINT&type=Date)](https://star-history.com/#Harery/SYSMAINT&Date)

**If you find SYSMAINT useful, please consider giving it a star! ⭐**

---

<div align="center">

**[Website](https://www.harery.com)** • **[Documentation](docs/)** • **[Support](https://github.com/Harery/SYSMAINT/issues)** • **[Discussions](https://github.com/Harery/SYSMAINT/discussions)**

Built with ❤️ for the Linux ecosystem

</div>
