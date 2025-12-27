# Troubleshooting

**SYSMAINT v1.0.0**

---

## Common Issues

### "Permission denied"

**Problem:** Cannot execute sysmaint script

**Solution:**
```bash
chmod +x sysmaint
sudo ./sysmaint
```

---

### "command not found: dialog"

**Problem:** Interactive mode requires dialog utility

**Solution:**

Ubuntu/Debian:
```bash
sudo apt install dialog
```

Fedora/RHEL/Rocky/Alma/CentOS:
```bash
sudo dnf install dialog
```

Arch Linux:
```bash
sudo pacman -S dialog
```

openSUSE:
```bash
sudo zypper install dialog
```

---

### Package manager errors

**Problem:** Cannot update packages due to locked package database

**Solution:**
```bash
# Remove lock files
sudo rm -f /var/lib/dpkg/lock-frontend
sudo rm -f /var/lib/dpkg/lock
sudo rm -f /var/cache/apt/archives/lock

# For RPM-based systems
sudo rm -f /var/lib/rpm/.rpm.lock
```

---

### Dry-run shows errors

**Problem:** Dry-run mode reports issues that won't occur in actual run

**Solution:** This is normal behavior. Dry-run mode performs validation checks. Review the warnings and proceed with the actual run if acceptable.

---

### Out of disk space

**Problem:** System runs out of space during cleanup

**Solution:**
```bash
# Check disk usage
df -h

# Clean package cache manually
# Ubuntu/Debian
sudo apt clean

# Fedora/RHEL
sudo dnf clean all

# Arch
sudo pacman -Sc
```

---

## Distribution-Specific Issues

### Ubuntu/Debian

**APT lock issues:**
```bash
# Wait for other apt processes to finish
sudo fuser -v /var/lib/dpkg/lock

# Or force remove locks
sudo rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
sudo dpkg --configure -a
```

### Fedora/RHEL

**DNF timeout:**
```bash
# Increase timeout
echo "timeout=300" | sudo tee -a /etc/dnf/dnf.conf
```

### Arch Linux

**Pacman key issues:**
```bash
sudo pacman-key --init
sudo pacman-key --populate
sudo pacman -Sy archlinux-keyring
```

---

## Debug Mode

Enable debug output:

```bash
# Run with debug mode
./sysmaint --debug

# Or with bash debug
bash -x sysmaint
```

---

## Getting Help

If you encounter issues not covered here:

1. Check [FAQ](FAQ)
2. [Open an issue](https://github.com/Harery/SYSMAINT/issues)
3. Email: [Mohamed@Harery.com](mailto:Mohamed@Harery.com)

---

## Project

https://github.com/Harery/SYSMAINT
