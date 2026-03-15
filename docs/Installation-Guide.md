# Installation Guide

**OCTALUM-PULSE v1.0.0**

---

## Requirements

- Linux system (one of the 9 supported distributions)
- Root/sudo access
- `dialog` utility for interactive mode
- Basic shell utilities (bash, coreutils)

---

## Method 1: Git Clone (Recommended)

```bash
# Clone the repository
git clone https://github.com/Harery/OCTALUM-PULSE.git
cd OCTALUM-PULSE

# Make executable
chmod +x pulse

# Test with dry-run
sudo ./pulse --dry-run

# Run normally
sudo ./pulse
```

---

## Method 2: Direct Download

```bash
# Download the script
curl -O https://raw.githubusercontent.com/Harery/OCTALUM-PULSE/main/pulse

# Make executable
chmod +x pulse

# Run
sudo ./pulse --dry-run
```

---

## Method 3: Docker

```bash
# Build the image
docker build -t pulse https://github.com/Harery/OCTALUM-PULSE.git

# Run in container
docker run --rm --privileged pulse
```

---

## Distribution-Specific Setup

### Ubuntu/Debian

```bash
sudo apt update
sudo apt install -y dialog git
git clone https://github.com/Harery/OCTALUM-PULSE.git
cd OCTALUM-PULSE
chmod +x pulse
sudo ./pulse --dry-run
```

### Fedora/RHEL/Rocky/Alma/CentOS

```bash
sudo dnf install -y dialog git
git clone https://github.com/Harery/OCTALUM-PULSE.git
cd OCTALUM-PULSE
chmod +x pulse
sudo ./pulse --dry-run
```

### Arch Linux

```bash
sudo pacman -S dialog git
git clone https://github.com/Harery/OCTALUM-PULSE.git
cd OCTALUM-PULSE
chmod +x pulse
sudo ./pulse --dry-run
```

### openSUSE

```bash
sudo zypper install dialog git
git clone https://github.com/Harery/OCTALUM-PULSE.git
cd OCTALUM-PULSE
chmod +x pulse
sudo ./pulse --dry-run
```

---

## Verification

```bash
# Check version
./pulse --version

# Test run (dry-run mode)
sudo ./pulse --dry-run

# View help
./pulse --help
```

---

## Post-Installation

### Configure Automatic Updates (Optional)

```bash
# Add to crontab for weekly runs
sudo crontab -e

# Add this line for weekly maintenance every Sunday at 2 AM
0 2 * * 0 /path/to/pulse --json > /var/log/pulse.log 2>&1
```

### Create Systemd Service (Optional)

Create `/etc/systemd/system/pulse.service`:

```ini
[Unit]
Description=OCTALUM-PULSE System Maintenance
After=network.target

[Service]
Type=oneshot
ExecStart=/path/to/pulse --json
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable pulse.service
sudo systemctl start pulse.service
```

---

## Troubleshooting

See [Troubleshooting](Troubleshooting) for common issues.

---

## Project

https://github.com/Harery/OCTALUM-PULSE
