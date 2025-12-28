# ❓ Frequently Asked Questions

**SYSMAINT v1.0.0 — Common Questions & Answers**

---

## Table of Contents

- [General Questions](#general-questions)
- [Usage Questions](#usage-questions)
- [Technical Questions](#technical-questions)
- [Error & Troubleshooting](#error--troubleshooting)
- [Development & Contributing](#development--contributing)
- [Getting Help](#getting-help)

---

## General Questions

### What is SYSMAINT?

**SYSMAINT** is an **enterprise-grade Linux system maintenance toolkit** that provides automated package management, intelligent system cleanup, security auditing, and performance optimization across **nine major Linux distributions**.

**Key Characteristics:**
- 🛠️ **Unified Interface** — One tool for all supported distributions
- 🔒 **Security-First** — Dry-run mode, input validation, no telemetry
- ⚡ **Fast & Efficient** — <3.5 minutes average runtime
- 🎯 **Comprehensive** — Handles packages, cleanup, kernels, and security
- 🤖 **Automation-Ready** — JSON output, CLI mode, cron/systemd support

---

### Which Linux distributions are supported?

| Distribution | Versions | Package Manager | Status |
|--------------|----------|:---------------:|:------:|
| **Ubuntu** | 22.04, 24.04 | `apt` | ✅ LTS |
| **Debian** | 12, 13 | `apt` | ✅ Stable |
| **Fedora** | 41 | `dnf` | ✅ Latest |
| **RHEL** | 9, 10 | `dnf/yum` | ✅ Enterprise |
| **Rocky Linux** | 9, 10 | `dnf/yum` | ✅ Enterprise |
| **AlmaLinux** | 9, 10 | `dnf/yum` | ✅ Enterprise |
| **CentOS Stream** | 9 | `dnf/yum` | ✅ Stream |
| **Arch Linux** | Rolling | `pacman` | ✅ Tested |
| **openSUSE** | Tumbleweed | `zypper` | ✅ Tested |

> **Note:** SYSMAINT may work on other distributions not listed here, but they are not officially tested or supported.

---

### Is SYSMAINT safe to use?

**Yes, SYSMAINT is designed with safety as a top priority:**

| Safety Feature | Description |
|---------------|-------------|
| **🔍 Dry-Run Mode** | Preview all changes without executing |
| **✅ Input Validation** | All parameters sanitized before execution |
| **🔒 Least Privilege** | Only requests necessary permissions |
| **📝 Audit Trail** | JSON logging for compliance and debugging |
| **🚫 No Telemetry** | Zero data collection or transmission |

**Best Practice:** Always run `sudo ./sysmaint --dry-run` before executing to review planned changes.

---

### Is SYSMAINT free to use?

**Yes!** SYSMAINT is released under the **MIT License**, which means:
- ✅ Free to use for personal and commercial purposes
- ✅ Free to modify and distribute
- ✅ No licensing fees or restrictions
- ✅ Open source and community-driven

---

## Usage Questions

### How often should I run SYSMAINT?

Recommended frequency depends on your use case:

| System Type | Recommended Frequency | Automation |
|-------------|----------------------|------------|
| **Personal Desktop/Laptop** | Weekly or bi-weekly | Optional |
| **Development Server** | Weekly | Recommended |
| **Production Server** | Weekly | Highly Recommended |
| **Critical Infrastructure** | After security advisories | Required |

**Setting up automation:**
```bash
# Systemd timer (recommended)
sudo systemctl enable --now sysmaint.timer

# Cron job
0 2 * * 0 /usr/local/sbin/sysmaint --auto --quiet
```

---

### Can I automate SYSMAINT?

**Yes!** SYSMAINT is designed for automation:

**Systemd Timer:**
```bash
sudo systemctl enable sysmaint.timer
sudo systemctl start sysmaint.timer
```

**Cron Job:**
```bash
# Weekly (Sundays at 2 AM)
0 2 * * 0 /usr/local/sbin/sysmaint --auto --quiet
```

**With JSON Logging:**
```bash
# Log to file with timestamp
/usr/local/sbin/sysmaint --auto --json > /var/log/sysmaint-$(date +%Y%m%d).json 2>&1
```

---

### What does dry-run mode actually do?

**Dry-run mode (`--dry-run`) performs read-only analysis:**

| Operation | Dry-Run Behavior |
|-----------|-----------------|
| **Package Updates** | Lists available updates, doesn't install |
| **Cleanup** | Identifies files to clean, calculates space savings |
| **Kernel Removal** | Shows which kernels would be removed |
| **Security Audit** | Performs actual security checks |
| **JSON Output** | Generates simulated results |

**Example:**
```bash
sudo ./sysmaint --dry-run --verbose
```

---

### Can I run specific operations only?

**Yes!** SYSMAINT supports granular operation selection:

| Option | Operation |
|--------|-----------|
| `--upgrade` | Package updates only |
| `--cleanup` | System cleanup only |
| `--purge-kernels` | Remove old kernels only |
| `--security-audit` | Security checks only |

**Combine options:**
```bash
# Updates + cleanup (no security audit)
sudo ./sysmaint --upgrade --cleanup

# Cleanup + security (no package updates)
sudo ./sysmaint --cleanup --security-audit
```

---

## Technical Questions

### Does SYSMAINT modify system configurations?

**No.** SYSMAINT **does not modify** configuration files such as:
- ❌ `/etc/fstab`
- ❌ `/etc/ssh/sshd_config`
- ❌ Systemd service files
- ❌ Application configuration files

**SYSMAINT only:**
- ✅ Updates software packages
- ✅ Cleans caches and temporary files
- ✅ Removes old kernel packages
- ✅ Reports security status

---

### Can I run SYSMAINT without root/sudo?

**Some operations work without root, but most require elevated privileges:**

| Operation | Root Required | Reason |
|-----------|:-------------:|--------|
| `--dry-run` | ❌ No | Read-only analysis |
| `--version` | ❌ No | Display information |
| `--upgrade` | ✅ Yes | Package installation |
| `--cleanup` | ✅ Yes | System file modification |
| `--security-audit` | ⚠️ Partial | Some checks need root |

---

### How much disk space can SYSMAINT recover?

**Disk recovery varies by system and usage patterns:**

| Source | Typical Recovery | Maximum Recovery |
|--------|-----------------|------------------|
| **Package Cache** | 500MB - 2GB | Up to 10GB+ |
| **Temporary Files** | 100MB - 1GB | Up to 5GB+ |
| **Old Logs** | 50MB - 500MB | Up to 2GB+ |
| **Old Kernels** | 200MB - 1GB | Up to 5GB+ |
| **Total** | **~1GB - 5GB** | **Up to 20GB+** |

**Check your potential savings:**
```bash
sudo ./sysmaint --dry-run --cleanup
```

---

### Does SYSMAINT delete user files?

**No!** SYSMAINT **never deletes** user data:

**Safe to clean:**
| Location | Type | Example |
|----------|------|---------|
| `/tmp/*` | Temporary files | Application temp files |
| `/var/tmp/*` | Variable temp | Package manager temp |
| `/var/cache/*` | Cache | Package caches, thumbnails |
| `/var/log/*` | Old logs | Compressed logs >90 days |

**Never touched:**
- ❌ `/home/*` — User home directories
- ❌ User documents, downloads, pictures, etc.
- ❌ User application data
- ❌ Custom configuration files

---

## Error & Troubleshooting

### What if SYSMAINT fails during execution?

**Troubleshooting steps:**

1. **Check the error message**
   ```bash
   sudo ./sysmaint --verbose 2>&1 | tee sysmaint.log
   ```

2. **Run dry-run to identify issues**
   ```bash
   sudo ./sysmaint --dry-run --verbose
   ```

3. **Review specific platform issues**
   - See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

4. **Report the issue**
   - Include: OS version, error message, and verbose log
   - Report at: https://github.com/Harery/SYSMAINT/issues

---

### Can I undo changes made by SYSMAINT?

**Some operations can be undone:**

| Operation | Undo Method |
|-----------|-------------|
| **Package Updates** | Rollback to previous version |
| **Package Removal** | Reinstall packages |
| **Cleanup** | Not easily recoverable |
| **Kernel Removal** | Reinstall from package cache |

**Rollback examples:**
```bash
# Ubuntu/Debian: Reinstall specific package
sudo apt install --reinstall package-name

# Fedora/RHEL: Use history
sudo dnf history undo

# Arch: Downgrade package
sudo downgrade package-name
```

> **Tip:** Package removals can't always be undone. Always review `--dry-run` output first.

---

### What if SYSMAINT freezes or hangs?

**If SYSMAINT appears frozen:**

1. **Check if package manager is waiting for input**
   ```bash
   # Check process status
   ps aux | grep sysmaint

   # Check if apt/dnf/pacman is waiting
   ps aux | grep -E "apt|dnf|pacman|zypper"
   ```

2. **Wait for package manager timeout**
   - Some operations can take several minutes
   - Package mirrors may be slow

3. **Kill frozen process (if necessary)**
   ```bash
   # Find process ID
   pgrep -f sysmaint

   # Terminate gracefully
   sudo kill -15 <PID>

   # Force kill (if needed)
   sudo kill -9 <PID>

   # Remove lock file
   sudo rm /var/run/sysmaint.lock
   ```

---

## Development & Contributing

### How can I contribute to SYSMAINT?

**We welcome contributions!** See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

**Ways to contribute:**

| Type | Examples |
|------|----------|
| **Bug Reports** | Submit issues with reproduction steps |
| **Feature Requests** | Propose new features via GitHub Discussions |
| **Code Contributions** | Pull requests for bug fixes or features |
| **Documentation** | Improve docs, fix typos, add examples |
| **Testing** | Test on your distribution and report results |

**Getting Started:**
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

### What tools were used to build SYSMAINT?

| Tool/Stack | Purpose |
|------------|---------|
| **Bash Scripting** | Core implementation language |
| **ShellCheck** | Static analysis & linting |
| **GitHub Actions** | CI/CD & testing |
| **Docker** | Containerization |
| **VS Code** | Development environment |
| **Claude Code** | AI-assisted development |

---

## Getting Help

### Where can I get support?

| Resource | Best For | Link |
|----------|----------|------|
| **Documentation** | General information, usage | [docs/](docs/) |
| **Troubleshooting Guide** | Common issues & solutions | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) |
| **GitHub Issues** | Bug reports, feature requests | [github.com/Harery/SYSMAINT/issues](https://github.com/Harery/SYSMAINT/issues) |
| **GitHub Discussions** | Questions, community help | [github.com/Harery/SYSMAINT/discussions](https://github.com/Harery/SYSMAINT/discussions) |
| **Email** | Private inquiries | [Mohamed@Harery.com](mailto:Mohamed@Harery.com) |

---

### Quick Reference: Common Commands

```bash
# Preview all changes (safe, read-only)
sudo ./sysmaint --dry-run

# Fully automated mode
sudo ./sysmaint --auto

# Package updates only
sudo ./sysmaint --upgrade

# System cleanup only
sudo ./sysmaint --cleanup

# Security audit only
sudo ./sysmaint --security-audit

# JSON output for monitoring/automation
sudo ./sysmaint --json-summary | jq .

# Verbose mode for debugging
sudo ./sysmaint --verbose

# Quiet mode for cron
sudo ./sysmaint --auto --quiet
```

---

### Still have questions?

1. **Check the documentation:**
   - [README.md](../README.md)
   - [Installation Guide](INSTALLATION.md)
   - [Troubleshooting](TROUBLESHOOTING.md)

2. **Search existing issues:**
   - [GitHub Issues](https://github.com/Harery/SYSMAINT/issues)

3. **Ask the community:**
   - [GitHub Discussions](https://github.com/Harery/SYSMAINT/discussions)

4. **Contact directly:**
   - [Email: Mohamed@Harery.com](mailto:Mohamed@Harery.com)

---

**Document Version:** v1.0.0
**Last Updated:** 2025-12-28
**Project:** https://github.com/Harery/SYSMAINT
