# 📥 Installation Guide

**OCTALUM-PULSE v1.0.0 — Complete Installation Instructions**

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Install](#quick-install)
- [Installation Methods](#installation-methods)
- [Distribution-Specific Setup](#distribution-specific-setup)
- [Automation Setup](#automation-setup)
- [Verification](#verification)
- [Uninstallation](#uninstallation)

---

## Prerequisites

### System Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| **Operating System** | Ubuntu 22.04+, Debian 12+, Fedora 41+, RHEL 9+, Arch, openSUSE Tumbleweed | Latest LTS version |
| **RAM** | 512 MB | 1 GB+ |
| **Disk Space** | 100 MB free | 500 MB+ |
| **Permissions** | sudo or root access | sudo or root access |
| **Bash** | 4.0+ | 5.0+ |
| **Network** | Internet connection (for package managers) | Stable connection |

### Required Packages

| Package | Purpose | Installation Command |
|---------|---------|---------------------|
| `git` | Clone repository | Varies by distribution |
| `curl` | Direct download | Varies by distribution |
| `dialog` | Interactive TUI | Varies by distribution |

---

## Quick Install

The fastest way to get started with OCTALUM-PULSE:

```bash
# Clone repository
git clone https://github.com/Harery/OCTALUM-PULSE.git
cd OCTALUM-PULSE

# Make executable
chmod +x pulse

# Preview (100% safe, read-only)
sudo ./pulse --dry-run

# Execute maintenance
sudo ./pulse
```

**Or use Docker:**
```bash
docker pull ghcr.io/harery/pulse:latest
docker run --rm --privileged ghcr.io/harery/pulse:latest
```

---

## Installation Methods

### Method 1: Git Clone (Recommended)

Best for: Users who want updates and easy modifications.

```bash
# Clone the repository
git clone https://github.com/Harery/OCTALUM-PULSE.git
cd OCTALUM-PULSE

# Make executable
chmod +x pulse

# Run with dry-run first
sudo ./pulse --dry-run

# Execute maintenance
sudo ./pulse
```

**Updating:**
```bash
cd OCTALUM-PULSE
git pull
```

---

### Method 2: Direct Download

Best for: Quick installation without git.

```bash
# Download the script
curl -O https://raw.githubusercontent.com/Harery/OCTALUM-PULSE/main/pulse

# Make executable
chmod +x pulse

# Run with dry-run first
sudo ./pulse --dry-run

# Execute maintenance
sudo ./pulse
```

**Updating:**
```bash
curl -O https://raw.githubusercontent.com/Harery/OCTALUM-PULSE/main/pulse
```

---

### Method 3: Docker

Best for: Containerized environments and testing.

```bash
# Pull the image
docker pull ghcr.io/harery/pulse:latest

# Run maintenance
docker run --rm --privileged ghcr.io/harery/pulse:latest

# Run specific operations
docker run --rm --privileged ghcr.io/harery/pulse:latest --auto --cleanup
```

**Docker Compose:**
```yaml
services:
  pulse:
    image: ghcr.io/harery/pulse:latest
    privileged: true
    volumes:
      - /:/host:ro
```

---

### Method 4: System-Wide Installation

Best for: Permanent installation with automation support.

```bash
# Install to system path
sudo install -Dm755 pulse /usr/local/sbin/pulse

# Install systemd service files (for automation)
sudo install -Dm644 packaging/systemd/pulse.service /etc/systemd/system/
sudo install -Dm644 packaging/systemd/pulse.timer /etc/systemd/system/

# Enable weekly automatic maintenance
sudo systemctl enable --now pulse.timer

# Verify installation
pulse --version
```

---

## Distribution-Specific Setup

### 🐧 Ubuntu / Debian

```bash
# Install dependencies
sudo apt update
sudo apt install -y git curl dialog

# Clone and install
git clone https://github.com/Harery/OCTALUM-PULSE.git
cd OCTALUM-PULSE
chmod +x pulse

# Run dry-run
sudo ./pulse --dry-run
```

**Dependencies:**
| Package | Version |
|---------|---------|
| `bash` | 4.0+ |
| `dialog` | 1.3+ |
| `apt-utils` | Latest |

---

### 🎩 Fedora / RHEL / Rocky Linux / AlmaLinux / CentOS

```bash
# Install dependencies
sudo dnf install -y git curl dialog

# Clone and install
git clone https://github.com/Harery/OCTALUM-PULSE.git
cd OCTALUM-PULSE
chmod +x pulse

# Run dry-run
sudo ./pulse --dry-run
```

**Dependencies:**
| Package | Version |
|---------|---------|
| `bash` | 4.0+ |
| `dialog` | 1.3+ |
| `dnf` or `yum` | Latest |

---

### 🎯 Arch Linux

```bash
# Install dependencies
sudo pacman -S git curl dialog

# Clone and install
git clone https://github.com/Harery/OCTALUM-PULSE.git
cd OCTALUM-PULSE
chmod +x pulse

# Run dry-run
sudo ./pulse --dry-run
```

**Dependencies:**
| Package | Version |
|---------|---------|
| `bash` | 5.0+ |
| `dialog` | Latest |
| `pacman` | Latest |

---

### 🦎 openSUSE

```bash
# Install dependencies
sudo zypper install -y git curl dialog

# Clone and install
git clone https://github.com/Harery/OCTALUM-PULSE.git
cd OCTALUM-PULSE
chmod +x pulse

# Run dry-run
sudo ./pulse --dry-run
```

**Dependencies:**
| Package | Version |
|---------|---------|
| `bash` | 4.0+ |
| `dialog` | Latest |
| `zypper` | Latest |

---

## Automation Setup

### Systemd Timer (Recommended)

```bash
# Install to system path
sudo install -Dm755 pulse /usr/local/sbin/pulse

# Install service and timer files
sudo install -Dm644 packaging/systemd/pulse.service /etc/systemd/system/
sudo install -Dm644 packaging/systemd/pulse.timer /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable and start timer
sudo systemctl enable --now pulse.timer

# Check status
sudo systemctl status pulse.timer

# View logs
sudo journalctl -u pulse.service -f
```

**Systemd Timer Schedule:**
- Default: Weekly (Sunday at 2:00 AM)
- Customizable: Edit `pulse.timer`

---

### Cron Job

```bash
# Edit crontab
crontab -e

# Add one of the following:

# Weekly (Sundays at 2 AM)
0 2 * * 0 /usr/local/sbin/pulse --auto --quiet

# Daily (at 3 AM)
0 3 * * * /usr/local/sbin/pulse --auto --quiet

# Monthly (1st of month at 4 AM)
0 4 1 * * /usr/local/sbin/pulse --auto --quiet
```

---

### Kubernetes CronJob

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: pulse
  namespace: default
spec:
  schedule: "0 2 * * 0"  # Weekly at 2 AM
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: pulse
            image: ghcr.io/harery/pulse:latest
            imagePullPolicy: Always
            securityContext:
              privileged: true
            resources:
              requests:
                memory: "128Mi"
                cpu: "100m"
              limits:
                memory: "256Mi"
                cpu: "500m"
          restartPolicy: OnFailure
```

---

## Verification

### Check Installation

```bash
# Verify script is executable
ls -l pulse

# Check version
./pulse --version

# Test dry-run
sudo ./pulse --dry-run
```

### Expected Output

```
OCTALUM-PULSE v1.0.0 - Enterprise Linux System Maintenance
=======================================================

[DRY-RUN MODE] No changes will be made.

Detected: Ubuntu 24.04 LTS
[+] Package management: OK
[+] System cleanup: OK
[+] Security audit: OK

Dry-run complete. Review output above.
```

---

## Uninstallation

### Remove from System Path

```bash
# Remove binary
sudo rm /usr/local/sbin/pulse

# Remove systemd files
sudo rm /etc/systemd/system/pulse.service
sudo rm /etc/systemd/system/pulse.timer

# Reload systemd
sudo systemctl daemon-reload

# Disable timer (if enabled)
sudo systemctl disable pulse.timer 2>/dev/null
```

### Remove Clone/Download

```bash
# If cloned via git
rm -rf OCTALUM-PULSE

# If downloaded directly
rm pulse
```

### Remove Docker Image

```bash
# Remove image
docker rmi ghcr.io/harery/pulse:latest

# Prune dangling images
docker image prune
```

---

## Troubleshooting

### "Permission denied"

```bash
# Make script executable
chmod +x pulse

# Run with sudo
sudo ./pulse
```

### "command not found: dialog"

```bash
# Ubuntu/Debian
sudo apt install dialog

# Fedora/RHEL
sudo dnf install dialog

# Arch
sudo pacman -S dialog

# openSUSE
sudo zypper install dialog
```

### "sudo: no tty present"

```bash
# Use non-interactive mode
sudo ./pulse --auto --quiet
```

> **📖 More Help:** [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## Next Steps

1. **Read the Documentation**
   - [Usage Guide](../README.md#usage)
   - [Configuration Options](../README.md#all-command-line-options)

2. **Set Up Automation**
   - [Systemd Timer](#systemd-timer-recommended)
   - [Cron Job](#cron-job)

3. **Configure Monitoring**
   - Enable JSON output for log aggregation
   - Set up alerts for failures

4. **Customize Behavior**
   - Edit configuration files (if available)
   - Create custom maintenance scripts

---

## Additional Resources

| Resource | Link |
|----------|------|
| **GitHub Repository** | https://github.com/Harery/OCTALUM-PULSE |
| **Docker Hub** | https://ghcr.io/harery/pulse |
| **Issue Tracker** | https://github.com/Harery/OCTALUM-PULSE/issues |
| **Discussions** | https://github.com/Harery/OCTALUM-PULSE/discussions |

---

**Document Version:** v1.0.0
**Last Updated:** 2025-12-28
**Project:** https://github.com/Harery/OCTALUM-PULSE
