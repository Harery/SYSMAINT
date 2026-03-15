# Changelog

All notable changes to OCTALUM-PULSE will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-03-15

### 🎉 Major Release - Complete Revamp

This is a complete rewrite from the ground up, transitioning from SYSMAINT (Bash) to OCTALUM-PULSE (Go).

### ✨ Added

#### Core
- **Go-based core engine** - Complete rewrite in Go for performance and reliability
- **Plugin system** - Extensible plugin architecture with WASM support
- **State engine** - SQLite-based operation history and metrics
- **Multi-arch support** - Native support for amd64 and arm64

#### CLI
- **New command structure** - `pulse` command with intuitive subcommands
- `pulse doctor` - Comprehensive system health check
- `pulse fix --auto` - Automatic issue remediation
- `pulse update --smart` - Intelligent package updates
- `pulse explain` - AI-powered change explanations
- `pulse rollback --last` - Instant rollback to previous state
- `pulse compliance check` - Regulatory compliance auditing
- `pulse tui` - Interactive terminal UI

#### Plugins
- **pulse-packages** - Package management abstraction (apt, dnf, pacman, zypper, apk)
- **pulse-security** - Security auditing and CVE scanning
- **pulse-performance** - System optimization and tuning
- **pulse-compliance** - Regulatory compliance (HIPAA, SOC2, PCI-DSS, CIS)
- **pulse-observability** - Prometheus/Grafana integration

#### AI/ML
- **Predictive maintenance** - Predict disk failures, memory issues
- **Intelligent recommendations** - Context-aware suggestions
- **Local AI support** - Ollama integration for offline AI
- **Cloud AI option** - OpenAI/Anthropic integration

#### Deployment
- **Docker images** - Multi-arch containers on GHCR
- **Helm chart** - Kubernetes deployment via Helm
- **Kubernetes manifests** - CronJob, DaemonSet, RBAC
- **Systemd integration** - Native systemd service files
- **Package repositories** - APT and RPM repositories

#### Documentation
- **New documentation site** - docs.pulse.harery.com
- **API documentation** - OpenAPI/Swagger specs
- **Plugin development guide** - For community contributors

### 🔧 Changed

- **Project name**: SYSMAINT → OCTALUM-PULSE
- **Language**: Bash → Go
- **Architecture**: Monolith → Plugin-based modular
- **CLI**: Raw arguments → Cobra-based CLI

### 🗑️ Removed

- Direct shell script execution (replaced by Go binary)
- Inline shell code (moved to plugins)

---

## [1.0.0] - 2025-12-28

### Initial Release (SYSMAINT)

#### Features
- Multi-distro support (9 distributions)
- Package management (apt, dnf, pacman, zypper)
- System cleanup (logs, cache, temp, kernels)
- Security auditing
- JSON output
- Dry-run mode
- Interactive TUI
- Docker support
- Kubernetes support
- Systemd timers
- 500+ tests

---

## Version History

| Version | Date | Type |
|---------|------|------|
| 2.0.0 | 2026-03-15 | Major |
| 1.0.0 | 2025-12-28 | Initial |
