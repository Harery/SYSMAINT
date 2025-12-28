# Installation Guide

**SYSMAINT v1.0.0 - Complete Installation Instructions**

---

## Quick Install

```bash
git clone https://github.com/Harery/SYSMAINT.git
cd SYSMAINT
chmod +x sysmaint
sudo ./sysmaint --dry-run
```

---

## Method 1: Git Clone (Recommended)

### Requirements
- Bash 4.0+
- sudo privileges
- Supported distribution

### Steps
```bash
git clone https://github.com/Harery/SYSMAINT.git
cd SYSMAINT
chmod +x sysmaint
sudo ./sysmaint --dry-run
sudo ./sysmaint
```

---

## Method 2: Direct Download

```bash
curl -O https://raw.githubusercontent.com/Harery/SYSMAINT/main/sysmaint
chmod +x sysmaint
sudo ./sysmaint --dry-run
```

---

## Method 3: Docker

```bash
docker pull ghcr.io/harery/sysmaint:latest
docker run --rm --privileged ghcr.io/harery/sysmaint:latest
```

---

## Method 4: System-Wide Installation

```bash
sudo install -Dm755 sysmaint /usr/local/sbin/sysmaint
sudo install -Dm644 packaging/systemd/sysmaint.{service,timer} /etc/systemd/system/
sudo systemctl enable --now sysmaint.timer
```

---

## Distribution-Specific Setup

### Ubuntu/Debian
```bash
sudo apt update
sudo apt install -y curl dialog
git clone https://github.com/Harery/SYSMAINT.git
cd SYSMAINT && chmod +x sysmaint
sudo ./sysmaint --dry-run
```

### Fedora/RHEL/Rocky/Alma
```bash
sudo dnf install -y git dialog
git clone https://github.com/Harery/SYSMAINT.git
cd SYSMAINT && chmod +x sysmaint
sudo ./sysmaint --dry-run
```

### Arch Linux
```bash
sudo pacman -S git dialog
git clone https://github.com/Harery/SYSMAINT.git
cd SYSMAINT && chmod +x sysmaint
sudo ./sysmaint --dry-run
```

### openSUSE
```bash
sudo zypper install -y git dialog
git clone https://github.com/Harery/SYSMAINT.git
cd SYSMAINT && chmod +x sysmaint
sudo ./sysmaint --dry-run
```

---

## Automation

### Cron (Weekly)
```bash
0 2 * * 0 /usr/local/sbin/sysmaint --auto --quiet
```

### Systemd Timer
```bash
sudo systemctl enable sysmaint.timer
sudo systemctl start sysmaint.timer
```

---

**Project:** https://github.com/Harery/SYSMAINT
