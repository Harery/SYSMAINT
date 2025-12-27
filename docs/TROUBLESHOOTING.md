# SYSMAINT Troubleshooting Guide

**Version:** v1.0.0
**Last Updated:** 2025-12-27

---

## Table of Contents

1. [Common Issues](#common-issues)
2. [Platform-Specific Issues](#platform-specific-issues)
3. [Permission Issues](#permission-issues)
4. [GUI/TUI Issues](#guitui-issues)
5. [Network Issues](#network-issues)

---

## Common Issues

### "Permission denied"

**Problem:**
```bash
$ ./sysmaint
bash: ./sysmaint: Permission denied
```

**Solution:**
```bash
chmod +x sysmaint
sudo ./sysmaint
```

---

### "command not found: dialog"

**Problem:**
```bash
ERROR: dialog or whiptail not found
```

**Solution:**
```bash
# Debian/Ubuntu
sudo apt install dialog

# Fedora/RHEL/Rocky/Alma
sudo dnf install dialog

# Arch Linux
sudo pacman -S dialog

# openSUSE
sudo zypper install dialog
```

---

### "GitHub CLI not configured"

**Problem:**
```bash
warning: unable to access '/home/user/.gitconfig': Is a directory
```

**Solution:**
```bash
# Remove incorrect .gitconfig directory
rm -rf ~/.gitconfig

# Configure git
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

---

## Platform-Specific Issues

### Debian/Ubuntu

**Issue: apt lock held by another process**
```bash
# Check what's holding the lock
sudo fuser /var/lib/dpkg/lock-frontend

# Wait for process or kill if safe
sudo kill -9 <PID>
```

---

### Fedora/RHEL/Rocky/Alma/CentOS

**Issue: dnf cache expired**
```bash
sudo dnf clean all
sudo dnf makecache
```

---

### Arch Linux

**Issue: pacman keyring issues**
```bash
sudo pacman -Sy archlinux-keyring
sudo pacman -Syu
```

---

### openSUSE

**Issue: zypper refresh fails**
```bash
sudo zypper refresh --force
```

---

## Permission Issues

### Sudo not configured

**Problem:**
```bash
user is not in the sudoers file
```

**Solution:**
```bash
# Login as root and add user to sudo/wheel group
# Debian/Ubuntu
su - root
usermod -aG sudo username

# Fedora/RHEL
su - root
usermod -aG wheel username
```

---

### Script needs root access

**Problem:**
Some operations require root privileges

**Solution:**
```bash
# Always run with sudo
sudo ./sysmaint

# Or use --dry-run for preview (no root needed)
./sysmaint --dry-run
```

---

## GUI/TUI Issues

### "GUI mode requires an interactive terminal"

**Problem:**
```bash
$ echo "Y" | sudo ./sysmaint --gui
ERROR: GUI mode requires an interactive terminal
```

**Solution:**
```bash
# Use --auto mode instead for non-interactive
sudo ./sysmaint --auto

# Or run GUI in actual terminal
sudo ./sysmaint --gui
```

---

### Terminal too small

**Problem:** Dialog menu doesn't display properly

**Solution:**
```bash
# Resize terminal to at least 80x24
# Or use CLI mode instead
sudo ./sysmaint --upgrade --cleanup
```

---

## Network Issues

### Package mirror slow/down

**Problem:** Package operations are very slow or timeout

**Solution:**
```bash
# Update mirrors
# Debian/Ubuntu
sudo apt update

# Fedora/RHEL
sudo dnf makecache --refresh

# Arch
sudo pacman -Sy

# openSUSE
sudo zypper refresh
```

---

### GitHub clone fails

**Problem:**
```bash
fatal: unable to access 'https://github.com/...'
```

**Solution:**
```bash
# Check internet connection
ping -c 3 github.com

# Use SSH instead
git clone git@github.com:Harery/SYSMAINT.git
```

---

## Docker Issues

### "Cannot connect to Docker daemon"

**Problem:**
```bash
docker: Cannot connect to the Docker daemon
```

**Solution:**
```bash
# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

---

## Getting More Help

If you're still experiencing issues:

1. **Check logs:**
   ```bash
   ./sysmaint --verbose | tee sysmaint.log
   ```

2. **Dry-run mode:**
   ```bash
   ./sysmaint --dry-run --verbose
   ```

3. **Report issues:**
   - https://github.com/Harery/SYSMAINT/issues
   - Include: OS version, error message, and verbose log

---

**Document Version:** v1.0.0
**Project:** https://github.com/Harery/SYSMAINT
