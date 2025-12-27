# Dependencies

**Version:** v1.0.0
**Last Updated:** 2025-12-27

---

## Runtime Dependencies

### Required

| Dependency | Minimum Version | Purpose | Install Command |
|------------|-----------------|---------|-----------------|
| **bash** | 4.0+ | Shell interpreter | `sudo apt install bash` |
| **systemd** | Any | Service management | Built-in on modern distros |

### Optional (Enhanced Features)

| Dependency | Purpose | Install Command |
|------------|---------|-----------------|
| **dialog** | TUI interface | `sudo apt install dialog` |
| **whiptail** | Alternative TUI | `sudo apt install whiptail` |
| **curl** | Download checks | `sudo apt install curl` |
| **wget** | Download checks | `sudo apt install wget` |

---

## Platform-Specific Dependencies

### Debian/Ubuntu

```bash
# Core dependencies
sudo apt update
sudo apt install bash systemd dialog

# Optional
sudo apt install curl wget whiptail
```

### Fedora/RHEL/Rocky/Alma/CentOS

```bash
# Core dependencies
sudo dnf install bash systemd dialog

# Optional
sudo dnf install curl wget newt
```

### Arch Linux

```bash
# Core dependencies
sudo pacman -S bash systemd dialog

# Optional
sudo pacman -S curl wget libnewt
```

### openSUSE

```bash
# Core dependencies
sudo zypper install bash systemd dialog

# Optional
sudo zypper install curl wget libnewt0
```

---

## Development Dependencies

### Required for Development

| Tool | Purpose | Install |
|------|---------|---------|
| **ShellCheck** | Code quality | `sudo apt install shellcheck` |
| **git** | Version control | `sudo apt install git` |
| **gh** | GitHub CLI | `https://cli.github.com/` |

### Optional for Development

| Tool | Purpose | Install |
|------|---------|---------|
| **jsonschema** | JSON validation | `pip install jsonschema` |
| **shfmt** | Code formatting | `https://github.com/mvdan/sh` |
| **bats-core** | Testing | `https://bats-core.readthedocs.io/` |

---

## No External Libraries

**SYSMAINT is self-contained:**

- ✅ No external bash libraries
- ✅ No npm/Python dependencies
- ✅ No external API calls
- ✅ No network dependencies (except optional checks)

---

## Dependency Updates

### Current Status

| Dependency | Version Used | Latest Stable | Status |
|------------|--------------|---------------|--------|
| bash | 4.0+ | 5.2+ | ✅ Compatible |
| systemd | Any | 255+ | ✅ Compatible |
| dialog | 1.0+ | 1.3+ | ✅ Compatible |

---

## Security

### Dependency Scanning

| Tool | Frequency | Status |
|------|-----------|--------|
| Manual review | Each release | ✅ Passed |
| ShellCheck | Each commit | ✅ Passed |
| Snyk (planned) | Weekly | 🔄 Pending |

### Known Vulnerabilities

**None reported** ✅

---

## License Compatibility

All dependencies are compatible with MIT License:

- **bash** - GPL v3 (system tool, not distributed)
- **systemd** - LGPL v2.1 (system tool, not distributed)
- **dialog** - LGPL v2.1 (optional, not distributed)

---

## Dependency Graph

```
sysmaint (main script)
├── init.sh (initialization)
│   └── lib/core/detection.sh (OS detection)
│       ├── lib/detector.sh (platform loader)
│       │   ├── lib/platforms/debian.sh
│       │   ├── lib/platforms/redhat.sh
│       │   ├── lib/platforms/arch.sh
│       │   └── lib/platforms/suse.sh
│       └── lib/core/*.sh (core utilities)
├── lib/modules/*.sh (maintenance modules)
└── dialog (optional TUI)
```

---

## Adding New Dependencies

### Guidelines

1. **Prefer built-in tools** over external dependencies
2. **Document thoroughly** in this file
3. **Check compatibility** across all 9 platforms
4. **Make optional** when possible
5. **Test thoroughly** before adding

### Process

1. Open issue discussing need
2. Get approval from maintainer
3. Update this documentation
4. Add feature flags if optional
5. Test on all platforms

---

## Dependency Removal

When removing dependencies:

1. Verify no active usage
2. Update documentation
3. Announce in release notes
4. Provide migration guide if needed

---

## Questions?

See [SUPPORT.md](SUPPORT.md) or open an issue.

---

**Project:** https://github.com/Harery/SYSMAINT
**Version:** v1.0.0
