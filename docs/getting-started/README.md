# Getting Started

This guide will help you get OCTALUM-PULSE up and running in minutes.

## Prerequisites

- Linux system (supported distribution)
- Root/sudo access (for most operations)
- Internet connection (for package updates)

## Quick Install

### One-Line Install

```bash
curl -sSL pulse.harery.com/install | bash
```

### Manual Install

```bash
# Download the latest release
curl -sSL https://github.com/Harery/OCTALUM-PULSE/releases/latest/download/pulse-linux-amd64 -o pulse

# Make executable
chmod +x pulse

# Move to PATH
sudo mv pulse /usr/local/bin/
```

## First Run

### Health Check

Start with a system health check:

```bash
pulse doctor
```

This runs a comprehensive check of your system without making any changes.

### Preview Changes

Preview what PULSE would do:

```bash
pulse update --dry-run
pulse cleanup --dry-run
```

### Apply Changes

When ready, run for real:

```bash
sudo pulse fix --auto
```

## Configuration

Create a configuration file:

```bash
mkdir -p ~/.config/pulse
cat > ~/.config/pulse/config.yaml << 'EOF'
version: 1
log_level: info

plugins:
  packages:
    enabled: true
  security:
    enabled: true
EOF
```

## Next Steps

- [CLI Reference](../reference/cli.md) - All commands and options
- [Configuration Guide](../guides/configuration.md) - Detailed configuration
- [Plugins](../plugins/README.md) - Plugin system overview
