# Migration Guide: SYSMAINT → OCTALUM-PULSE

This guide helps you migrate from SYSMAINT (v1.x) to OCTALUM-PULSE (v2.0).

## Overview

| Aspect | SYSMAINT (v1.x) | OCTALUM-PULSE (v2.0) |
|--------|-----------------|----------------------|
| **Language** | Bash | Go |
| **Architecture** | Monolithic script | Modular plugin system |
| **Installation** | Single script | Binary + plugins |
| **Configuration** | Environment variables | YAML config file |
| **State** | None | SQLite database |

## Command Mapping

| SYSMAINT Command | OCTALUM-PULSE Command |
|------------------|----------------------|
| `./sysmaint` | `pulse --auto` |
| `./sysmaint --dry-run` | `pulse --dry-run` |
| `./sysmaint --auto` | `pulse --auto` |
| `./sysmaint --gui` | `pulse tui` |
| `./sysmaint --upgrade` | `pulse update` |
| `./sysmaint --cleanup` | `pulse cleanup` |
| `./sysmaint --purge-kernels` | `pulse cleanup --kernels` |
| `./sysmaint --security-audit` | `pulse security audit` |
| `./sysmaint --json-summary` | `pulse --json` |
| `./sysmaint --detect` | `pulse doctor` |

## New Commands in v2.0

| Command | Description |
|---------|-------------|
| `pulse doctor` | System health check |
| `pulse fix --auto` | Automatic issue remediation |
| `pulse update --smart` | Intelligent package updates |
| `pulse explain` | AI-powered change explanations |
| `pulse rollback --last` | Instant rollback |
| `pulse compliance check` | Compliance auditing |
| `pulse plugin list` | Plugin management |

## Configuration Migration

### Old (SYSMAINT)
```bash
export LOG_DIR=/var/log/sysmaint
export AUTO_REBOOT=true
sudo ./sysmaint
```

### New (OCTALUM-PULSE)
```yaml
# ~/.config/pulse/config.yaml
version: 1
log_level: info

plugins:
  packages:
    enabled: true
    auto_reboot: true

paths:
  log_dir: /var/log/pulse
```

## Installation Migration

### Step 1: Remove SYSMAINT

```bash
sudo rm -f /usr/local/sbin/sysmaint
sudo rm -rf /tmp/system-maintenance
sudo systemctl disable sysmaint.timer 2>/dev/null || true
```

### Step 2: Install OCTALUM-PULSE

```bash
curl -sSL pulse.harery.com/install | bash
```

### Step 3: Create Configuration

```bash
mkdir -p ~/.config/pulse
cat > ~/.config/pulse/config.yaml << 'EOF'
version: 1
log_level: info

plugins:
  packages:
    enabled: true
    security_only: false
  security:
    enabled: true
    standards: [cis]
  performance:
    enabled: true
EOF
```

### Step 4: Verify Installation

```bash
pulse doctor
```

## Systemd Migration

### Old
```
/etc/systemd/system/sysmaint.service
/etc/systemd/system/sysmaint.timer
```

### New
```
/etc/systemd/system/pulse.service
/etc/systemd/system/pulse.timer
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now pulse.timer
```

## Docker Migration

### Old
```bash
docker run --rm --privileged ghcr.io/harery/sysmaint:latest
```

### New
```bash
docker run --rm --privileged ghcr.io/harery/octalum-pulse:latest
```

## Kubernetes Migration

### Old
```yaml
image: ghcr.io/harery/sysmaint:latest
```

### New
```yaml
image: ghcr.io/harery/octalum-pulse:latest
```

## Data Migration

SYSMAINT doesn't store persistent data, so no data migration is needed. OCTALUM-PULSE will create a new SQLite database at:
- `~/.local/share/pulse/pulse.db`

## Feature Parity

| Feature | v1.x | v2.0 |
|---------|------|------|
| Package updates | ✅ | ✅ |
| System cleanup | ✅ | ✅ |
| Security audit | ✅ | ✅ |
| Kernel management | ✅ | ✅ |
| JSON output | ✅ | ✅ |
| Dry-run mode | ✅ | ✅ |
| Interactive TUI | ✅ | ✅ |
| Docker support | ✅ | ✅ |
| Kubernetes | ✅ | ✅ |
| Plugin system | ❌ | ✅ |
| AI diagnostics | ❌ | ✅ |
| Rollback | ❌ | ✅ |
| Compliance checks | ❌ | ✅ |
| State history | ❌ | ✅ |
| Web dashboard | ❌ | ✅ |

## Troubleshooting

### "pulse: command not found"

```bash
# Add to PATH
export PATH=$PATH:/usr/local/bin
# Or reinstall
curl -sSL pulse.harery.com/install | bash
```

### "permission denied"

Most operations require root:
```bash
sudo pulse doctor
```

### Configuration not found

Create default config:
```bash
mkdir -p ~/.config/pulse
pulse --help  # Creates default config
```

## Getting Help

- **Documentation**: https://docs.pulse.harery.com
- **Discord**: https://discord.gg/pulse
- **GitHub Issues**: https://github.com/Harery/OCTALUM-PULSE/issues
