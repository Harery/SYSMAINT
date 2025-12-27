# Frequently Asked Questions

**Version:** v1.0.0
**Last Updated:** 2025-12-27

---

## General Questions

### What is SYSMAINT?

SYSMAINT is an automated Linux system maintenance tool that supports 9 major Linux distributions. It provides a single command to update, clean, and secure your system.

### Which distributions are supported?

- Ubuntu 24.04, 22.04
- Debian 13, 12
- Fedora 41
- RHEL 10
- Rocky Linux 9
- AlmaLinux 9
- CentOS Stream 9
- Arch Linux
- openSUSE Tumbleweed

### Is SYSMAINT free?

Yes! SYSMAINT is open-source and released under the MIT License.

---

## Installation & Usage

### How do I install SYSMAINT?

```bash
git clone https://github.com/Harery/SYSMAINT.git
cd SYSMAINT
chmod +x sysmaint
sudo ./sysmaint
```

### Do I need to use sudo?

Yes, SYSMAINT requires root privileges to perform system maintenance tasks.

### Can I run it automatically?

Yes! You can set up a cron job:

```bash
# Run weekly on Sunday at 2 AM
0 2 * * 0 /path/to/sysmaint/sysmaint --auto
```

---

## Safety & Security

### Will SYSMAINT delete my data?

No! SYSMAINT only removes:
- Old kernel packages (keeping the latest 2)
- Cached package files
- Temporary files
- Old log files (rotated, not active logs)

### Is it safe to run?

Yes! SYSMAINT includes:
- Input validation on all operations
- Dry-run mode to preview changes: `sudo ./sysmaint --dry-run`
- Confirmation prompts for destructive operations
- Comprehensive testing on all supported platforms

### Does SYSMAINT collect data?

No! SYSMAINT has zero telemetry and collects no data.

---

## Troubleshooting

### "Permission denied" error

```bash
chmod +x sysmaint
sudo ./sysmaint
```

### "command not found: dialog"

Install dialog for the TUI interface:

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

### SYSMAINT doesn't detect my distribution

Please open an issue with:
- Your distribution name and version
- Output of: `cat /etc/os-release`
- Any error messages

See [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md) for more help.

---

## Development

### How can I contribute?

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

### What coding standards are used?

- Shell Script (Bash 4.0+)
- 4-space indentation
- ShellCheck compliance (zero errors)
- Function documentation headers

### How do I run tests?

```bash
# Quick smoke test
bash tests/test_suite_smoke.sh

# Full test suite
bash tests/test_profile_ci.sh

# Check code quality
shellcheck -x sysmaint lib/**/*.sh
```

---

## Support

### Where can I get help?

- [Documentation](README.md)
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
- [Support Policy](SUPPORT.md)
- [GitHub Issues](https://github.com/Harery/SYSMAINT/issues)
- [Email: Mohamed@Harery.com](mailto:Mohamed@Harery.com)

### How do I report a bug?

Open an issue on GitHub with:
- Distribution and version
- Steps to reproduce
- Expected vs actual behavior
- Error messages

### How do I request a feature?

Open an issue with the `enhancement` label and describe:
- The problem you're solving
- Proposed solution
- Alternative approaches considered

---

## License

MIT License - See [LICENSE](../LICENSE)

---

**Project:** https://github.com/Harery/SYSMAINT
**Version:** v1.0.0
