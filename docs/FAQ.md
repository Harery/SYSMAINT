# FAQ

**Frequently Asked Questions**

---

## General Questions

### What is SYSMAINT?

SYSMAINT is an automated system maintenance toolkit for Linux that handles package updates, system cleanup, security auditing, and performance optimization.

---

### Which distributions are supported?

| Distribution | Versions |
|--------------|----------|
| Ubuntu | 22.04, 24.04 |
| Debian | 12, 13 |
| Fedora | 41 |
| RHEL | 10 |
| Rocky Linux | 9 |
| AlmaLinux | 9 |
| CentOS Stream | 9 |
| Arch Linux | Rolling |
| openSUSE | Tumbleweed |

---

### Is SYSMAINT safe to use?

Yes. SYSMAINT includes:
- Input validation
- Dry-run mode for testing
- Least privilege principle
- No data collection

**Always run with `--dry-run` first to preview changes.**

---

## Usage Questions

### How often should I run SYSMAINT?

Recommended:
- **Personal systems:** Weekly or bi-weekly
- **Servers:** Weekly with scheduled automation
- **Critical systems:** After security updates are available

---

### Can I automate SYSMAINT?

Yes, use cron or systemd:

**Cron (weekly):**
```bash
0 2 * * 0 /path/to/sysmaint --json > /var/log/sysmaint.log 2>&1
```

**Systemd timer:**
```bash
sudo systemctl enable sysmaint.timer
sudo systemctl start sysmaint.timer
```

---

### What does dry-run mode do?

Dry-run mode shows what would be done without making changes:
- Checks for available updates
- Identifies cleanable files
- Reports security issues
- Validates system state

---

## Technical Questions

### Does SYSMAINT modify system configurations?

No. SYSMAINT only:
- Updates packages
- Cleans caches and temporary files
- Reports security issues

It does not modify configuration files.

---

### Can I run SYSMAINT without root?

Some features work without root, but package updates and system cleanup require root/sudo privileges.

---

### How much disk space can SYSMAINT free?

This varies by system, but typically:
- Package caches: 500MB - 5GB
- Temporary files: 100MB - 2GB
- Log rotation: Variable

Use `--dry-run` to see potential space savings.

---

### Does SYSMAINT remove important files?

No. SYSMAINT only removes:
- Package manager caches
- Temporary files in /tmp
- Old log files (per logrotate config)
- Thumbnail caches

---

## Error Questions

### What if SYSMAINT fails?

1. Check the error message
2. Run with `--debug` for details
3. See [Troubleshooting](Troubleshooting)
4. Open an issue on GitHub

---

### Can I undo changes made by SYSMAINT?

Package updates can be rolled back:
```bash
# Ubuntu/Debian
sudo apt install --reinstall package-name

# Fedora/RHEL
sudo history undo

# Arch
sudo downgrade package-name
```

---

## Development Questions

### How can I contribute?

See [CONTRIBUTING.md](https://github.com/Harery/SYSMAINT/blob/main/CONTRIBUTING.md)

### What tools were used to build SYSMAINT?

| Tool | Purpose |
|------|---------|
| VS Code | Development environment |
| Claude | Code generation |
| Cline | Debugging |
| Kilo | Code analysis |

---

## Getting More Help

- **Issues:** https://github.com/Harery/SYSMAINT/issues
- **Email:** [Mohamed@Harery.com](mailto:Mohamed@Harery.com)
- **Documentation:** https://github.com/Harery/SYSMAINT

---

## Project

https://github.com/Harery/SYSMAINT
