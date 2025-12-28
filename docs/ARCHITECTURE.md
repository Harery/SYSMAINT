# Architecture

**SYSMAINT Modular Platform Architecture**

---

## Directory Structure

```
sysmaint/
├── sysmaint              # Main entry point
├── lib/
│   ├── core/            # Init, detection, logging, errors
│   ├── platform/        # Platform-specific modules (9 platforms)
│   ├── os_families/      # Family overrides
│   ├── maintenance/     # Operations (packages, kernel, etc)
│   ├── validation/      # Security & system validation
│   ├── progress/        # Progress tracking
│   ├── reporting/       # JSON output
│   └── gui/             # Interactive TUI
├── tests/               # 500+ tests
└── docs/                # Documentation
```

---

## Component Layers

1. **Core Layer** - Initialization, detection, logging
2. **Platform Layer** - Debian, RedHat, Arch, SUSE implementations
3. **Maintenance Layer** - Packages, kernel, storage, snap, flatpak
4. **Validation Layer** - Security, services, repos, keys
5. **Progress Layer** - Panel, estimates, parallel execution
6. **Reporting Layer** - Summary, JSON, reboot detection

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General Error |
| 10 | Repository Issues |
| 20 | Missing Keys |
| 30 | Failed Services |
| 75 | Lock Timeout |
| 100 | Reboot Required |

---

**Project:** https://github.com/Harery/SYSMAINT
