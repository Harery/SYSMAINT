# Migration Guide: OCTALUM-PULSE → OCTALUM-PULSE

This guide helps you migrate from OCTALUM-PULSE (v1.x) to OCTALUM-PULSE (v2.0).

## Overview

| Aspect | OCTALUM-PULSE (v1.x) | OCTALUM-PULSE (v2.0) |
|--------|-----------------|----------------------|
| **Language** | Bash | Go |
| **Architecture** | Monolithic script | Modular plugin system |
| **Installation** | Single script | Binary + plugins |
| **Configuration** | Environment variables | YAML config file |
| **State** | None | SQLite database |

## Command Mapping

| OCTALUM-PULSE Command | OCTALUM-PULSE Command |
|------------------|----------------------|
| `./pulse` | `pulse --auto` |
| `./pulse --dry-run` | `pulse --dry-run` |
| `./pulse --auto` | `pulse --auto` |
| `./pulse --gui` | `pulse tui` |
| `./pulse --upgrade` | `pulse update` |
| `./pulse --cleanup` | `pulse cleanup` |
| `./pulse --purge-kernels` | `pulse cleanup --kernels` |
| `./pulse --security-audit` | `pulse security audit` |
| `./pulse --json-summary` | `pulse --json` |
| `./pulse --detect` | `pulse doctor` |

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

### Old (OCTALUM-PULSE)
```bash
export LOG_DIR=/var/log/pulse
export AUTO_REBOOT=true
sudo ./pulse
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

### Step 1: Remove OCTALUM-PULSE

```bash
sudo rm -f /usr/local/sbin/pulse
sudo rm -rf /tmp/system-maintenance
sudo systemctl disable pulse.timer 2>/dev/null || true
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
/etc/systemd/system/pulse.service
/etc/systemd/system/pulse.timer
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
docker run --rm --privileged ghcr.io/harery/pulse:latest
```

### New
```bash
docker run --rm --privileged ghcr.io/harery/octalum-pulse:latest
```

## Kubernetes Migration

### Old
```yaml
image: ghcr.io/harery/pulse:latest
```

### New
```yaml
image: ghcr.io/harery/octalum-pulse:latest
```

## Data Migration

OCTALUM-PULSE doesn't store persistent data, so no data migration is needed. OCTALUM-PULSE will create a new SQLite database at:
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
