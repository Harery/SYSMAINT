# Installation Guide

**SYSMAINT v1.0.0**

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
git clone https://github.com/Harery/SYSMAINT.git
cd SYSMAINT

# Make executable
chmod +x sysmaint

# Test with dry-run
sudo ./sysmaint --dry-run

# Run normally
sudo ./sysmaint
```

---

## Method 2: Direct Download

```bash
# Download the script
curl -O https://raw.githubusercontent.com/Harery/SYSMAINT/main/sysmaint

# Make executable
chmod +x sysmaint

# Run
sudo ./sysmaint --dry-run
```

---

## Method 3: Docker

```bash
# Build the image
docker build -t sysmaint https://github.com/Harery/SYSMAINT.git

# Run in container
docker run --rm --privileged sysmaint
```

---

## Distribution-Specific Setup

### Ubuntu/Debian

```bash
sudo apt update
sudo apt install -y dialog git
git clone https://github.com/Harery/SYSMAINT.git
cd SYSMAINT
chmod +x sysmaint
sudo ./sysmaint --dry-run
```

### Fedora/RHEL/Rocky/Alma/CentOS

```bash
sudo dnf install -y dialog git
git clone https://github.com/Harery/SYSMAINT.git
cd SYSMAINT
chmod +x sysmaint
sudo ./sysmaint --dry-run
```

### Arch Linux

```bash
sudo pacman -S dialog git
git clone https://github.com/Harery/SYSMAINT.git
cd SYSMAINT
chmod +x sysmaint
sudo ./sysmaint --dry-run
```

### openSUSE

```bash
sudo zypper install dialog git
git clone https://github.com/Harery/SYSMAINT.git
cd SYSMAINT
chmod +x sysmaint
sudo ./sysmaint --dry-run
```

---

## Verification

```bash
# Check version
./sysmaint --version

# Test run (dry-run mode)
sudo ./sysmaint --dry-run

# View help
./sysmaint --help
```

---

## Post-Installation

### Configure Automatic Updates (Optional)

```bash
# Add to crontab for weekly runs
sudo crontab -e

# Add this line for weekly maintenance every Sunday at 2 AM
0 2 * * 0 /path/to/sysmaint --json > /var/log/sysmaint.log 2>&1
```

### Create Systemd Service (Optional)

Create `/etc/systemd/system/sysmaint.service`:

```ini
[Unit]
Description=SYSMAINT System Maintenance
After=network.target

[Service]
Type=oneshot
ExecStart=/path/to/sysmaint --json
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable sysmaint.service
sudo systemctl start sysmaint.service
```

---

## Troubleshooting

See [Troubleshooting](Troubleshooting) for common issues.

---

## Project

https://github.com/Harery/SYSMAINT
