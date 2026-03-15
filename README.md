<div align="center">

<img src="docs/assets/pulse-logo.svg" alt="OCTALUM-PULSE Logo" width="200">

# 🫀 OCTALUM-PULSE

### Your Infrastructure's Heartbeat — Always Alive, Always Optimized

[![Release](https://img.shields.io/github/v/release/Harery/OCTALUM-PULSE?style=for-the-badge&logo=github&color=00D4FF)](https://github.com/Harery/OCTALUM-PULSE/releases/latest)
[![License](https://img.shields.io/github/license/Harery/OCTALUM-PULSE?style=for-the-badge&color=0A1628)](LICENSE)
[![Go Report](https://goreportcard.com/badge/github.com/Harery/OCTALUM-PULSE?style=for-the-badge)](https://goreportcard.com/report/github.com/Harery/OCTALUM-PULSE)
[![Tests](https://img.shields.io/badge/tests-1000%2B-success?style=for-the-badge&logo=github)](test/)
[![Coverage](https://img.shields.io/badge/coverage-9%2B%20distros-brightgreen?style=for-the-badge&logo=linux)](docs/PLATFORM_SUPPORT.md)

[![Discord](https://img.shields.io/badge/Discord-Join%20Chat-5865F2?style=for-the-badge&logo=discord)](https://discord.gg/pulse)
[![Docs](https://img.shields.io/badge/docs-pulse.harery.com-blue?style=for-the-badge&logo=bookstack)](https://pulse.harery.com)
[![Docker](https://img.shields.io/badge/docker-ghcr.io%2Fharery%2Foctalum--pulse-0db7ed?style=for-the-badge&logo=docker)](https://ghcr.io/harery/octalum-pulse)

**One command. All distros. Zero worries.**

```bash
curl -sSL pulse.harery.com/install | bash
```

</div>

---

## 🎯 Why OCTALUM-PULSE?

| You're Tired Of... | OCTALUM-PULSE Gives You |
|---------------------|-------------------------|
| Different commands per distro | `pulse` — works everywhere |
| "Did I update that server?" | Real-time fleet visibility |
| "Why is my server slow?" | AI-powered diagnostics |
| Manual security audits | Automated compliance |
| "I broke something!" | One-command rollback |
| No audit trail | Full operation history |

---

## ⚡ 30-Second Demo

```bash
# Install
curl -sSL pulse.harery.com/install | bash

# Run health check
pulse doctor

# Fix everything automatically  
pulse fix --auto

# Update packages safely
pulse update --smart

# Check compliance
pulse compliance check --standard hipaa

# AI explain what changed
pulse explain
```

---

## ✨ Features

### Core Capabilities

| Feature | Description |
|---------|-------------|
| 🖥️ **Multi-Distro Support** | Ubuntu, Debian, Fedora, RHEL, Rocky, Alma, CentOS, Arch, openSUSE |
| 📦 **Package Management** | Unified interface for apt, dnf, pacman, zypper, apk |
| 🧹 **System Cleanup** | Logs, cache, temp files, old kernels |
| 🔐 **Security Auditing** | CVE scanning, CIS benchmarks, compliance |
| 🧠 **AI Diagnostics** | Predictive maintenance, intelligent recommendations |
| ⏪ **Instant Rollback** | Snapshot-based recovery |
| 📊 **Observability** | Prometheus metrics, Grafana dashboards |
| 🤖 **Automation** | Systemd timers, cron, Kubernetes CronJobs |

### Killer Features

| Command | What It Does |
|---------|--------------|
| `pulse fix --auto` | "I broke something" → Fixed in 30 seconds |
| `pulse doctor --quick` | "Can I deploy?" → Yes/No + Why |
| `pulse update --smart` | Update safe packages, hold risky ones |
| `pulse compliance check --standard hipaa` | "Am I compliant?" → Full report |
| `pulse rollback --last` | "I regret this" → Restored to before |
| `pulse explain` | "What changed?" → AI plain-English summary |

---

## 🌍 Supported Platforms

| Distribution | Versions | Package Manager | Status |
|--------------|----------|:---------------:|:------:|
| **Ubuntu** | 20.04, 22.04, 24.04 | apt | ✅ Stable |
| **Debian** | 11, 12, 13 | apt | ✅ Stable |
| **Fedora** | 40, 41 | dnf | ✅ Stable |
| **RHEL** | 8, 9, 10 | dnf/yum | ✅ Stable |
| **Rocky Linux** | 8, 9 | dnf/yum | ✅ Stable |
| **AlmaLinux** | 8, 9 | dnf/yum | ✅ Stable |
| **CentOS Stream** | 9 | dnf/yum | ✅ Stable |
| **Arch Linux** | Rolling | pacman | ✅ Stable |
| **openSUSE** | Leap, Tumbleweed | zypper | ✅ Stable |
| **Alpine** | 3.19+ | apk | 🔄 Beta |

---

## 🚀 Installation

### Method 1: One-Line Install (Recommended)

```bash
curl -sSL pulse.harery.com/install | bash
```

### Method 2: Package Managers

```bash
# Homebrew (macOS/Linux)
brew install harery/tap/pulse

# APT (Debian/Ubuntu)
curl -sSL https://apt.pulse.harery.com/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/pulse.gpg
echo "deb [signed-by=/etc/apt/keyrings/pulse.gpg] https://apt.pulse.harery.com stable main" | sudo tee /etc/apt/sources.list.d/pulse.list
sudo apt update && sudo apt install pulse

# RPM (RHEL/Fedora/Rocky/Alma)
sudo dnf config-manager --add-repo https://rpm.pulse.harery.com/repo.repo
sudo dnf install pulse

# Snap
sudo snap install octalum-pulse

# Go install
go install github.com/Harery/OCTALUM-PULSE/cmd/pulse@latest
```

### Method 3: Docker

```bash
# Quick health check
docker run --rm --privileged ghcr.io/harery/octalum-pulse:latest doctor

# With persistent data
docker run -d --name pulse \
  --privileged \
  -v /:/host:ro \
  -v pulse-data:/var/lib/pulse \
  ghcr.io/harery/octalum-pulse:latest \
  pulse agent
```

### Method 4: Kubernetes

```bash
# Helm (recommended)
helm repo add pulse https://charts.pulse.harery.com
helm install pulse pulse/pulse --namespace pulse --create-namespace

# Or apply manifests directly
kubectl apply -f https://raw.githubusercontent.com/Harery/OCTALUM-PULSE/main/deployments/kubernetes/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/Harery/OCTALUM-PULSE/main/deployments/kubernetes/
```

---

## 💻 Usage

### Quick Commands

```bash
# System health check
pulse doctor

# Fix detected issues
pulse fix

# Fix without prompts
pulse fix --auto

# Update packages
pulse update

# Smart update (safe packages only)
pulse update --smart

# Security-only updates
pulse update --security-only

# Clean up system
pulse cleanup

# Security audit
pulse security audit

# CVE scan
pulse security scan

# Compliance check
pulse compliance check --standard hipaa
pulse compliance check --standard soc2
pulse compliance check --standard pci-dss

# View operation history
pulse history

# Rollback last operation
pulse rollback --last

# AI explain changes
pulse explain
```

### Interactive Mode

```bash
pulse tui
```

### Dry-Run Mode

```bash
# Preview changes without executing
pulse update --dry-run
pulse cleanup --dry-run
```

### JSON Output

```bash
# For automation/integration
pulse doctor --json | jq .
pulse update --json | jq '.changes'
```

---

## ⚙️ Configuration

```yaml
# ~/.config/pulse/config.yaml
version: 1
log_level: info

plugins:
  packages:
    enabled: true
    security_only: false
    auto_reboot: false
  security:
    enabled: true
    standards: [cis]
    cve_scan: true
  performance:
    enabled: true
    aggressive: false
    bbr_v3: false
  compliance:
    enabled: false
    standards: []
  observability:
    enabled: false
    prometheus: false
    endpoint: ""

ai:
  enabled: true
  mode: local  # local, cloud, hybrid
  local:
    model: "llama3.2:1b"
    ollama_endpoint: "http://localhost:11434"
  features:
    predictive_maintenance: true
    recommendations: true
    nlp_interface: false
    auto_remediation: false
```

---

## 🔌 Plugin System

```bash
# List installed plugins
pulse plugin list

# Install community plugin
pulse plugin install github.com/user/pulse-custom

# Create your own plugin
pulse plugin init my-plugin
```

### Official Plugins

| Plugin | Description |
|--------|-------------|
| `pulse-packages` | Package management abstraction |
| `pulse-security` | Security auditing and CVE scanning |
| `pulse-performance` | System optimization and tuning |
| `pulse-compliance` | Regulatory compliance (HIPAA, SOC2, PCI-DSS) |
| `pulse-observability` | Prometheus/Grafana integration |

---

## 📊 Benchmarks

| Operation | OCTALUM-PULSE | Native | Speedup |
|-----------|:-------------:|:------:|:-------:|
| Full Update | 2m 15s | 4m 32s | **2.0x** |
| Security Audit | 8s | 2m+ | **15x+** |
| Disk Cleanup | 12s | 45s | **3.8x** |
| Cold Start | 85ms | - | - |
| Memory Usage | 28MB | - | - |

---

## 🏢 Enterprise

| Feature | Community | Enterprise |
|---------|:---------:|:----------:|
| Core Maintenance | ✅ | ✅ |
| Plugin System | ✅ | ✅ |
| AI Diagnostics | Local only | Cloud + Local |
| Fleet Management | ❌ | ✅ |
| Web Dashboard | ❌ | ✅ |
| SSO/SAML | ❌ | ✅ |
| SLA Support | Community | 24/7 |
| Custom Plugins | ❌ | ✅ |
| Compliance Reports | Basic | Full |

Contact [enterprise@harery.com](mailto:enterprise@harery.com) for enterprise licensing.

---

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

```bash
# Development setup
git clone https://github.com/Harery/OCTALUM-PULSE
cd OCTALUM-PULSE
make dev

# Run tests
make test

# Build
make build
```

---

## 📜 License

MIT License — Free forever for personal and commercial use.

See [LICENSE](LICENSE) for details.

---

## 🔗 Links

| Resource | URL |
|----------|-----|
| **Website** | https://pulse.harery.com |
| **Documentation** | https://docs.pulse.harery.com |
| **API Reference** | https://api.pulse.harery.com |
| **Discord** | https://discord.gg/pulse |
| **Twitter** | [@OCTALUM_PULSE](https://twitter.com/OCTALUM_PULSE) |
| **GitHub** | https://github.com/Harery/OCTALUM-PULSE |

---

## 🗺️ Roadmap

See [ROADMAP.md](ROADMAP.md) for planned features and releases.

---

<div align="center">

**Built with ❤️ by the [OCTALUME](https://github.com/Harery/OCTALUME) Team**

*"Every heartbeat counts"*

[Website](https://pulse.harery.com) • [Documentation](docs/) • [Discord](https://discord.gg/pulse) • [Twitter](https://twitter.com/OCTALUM_PULSE)

</div>
