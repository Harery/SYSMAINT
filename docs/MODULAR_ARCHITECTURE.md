# SYSMAINT Modular Platform Architecture

**Version:** v1.0.0
**Last Updated:** 2025-12-27

---

## Overview

SYSMAINT uses a modular architecture that isolates OS-specific code into separate platform modules. This design ensures that changes for one distribution don't affect others.

---

## Architecture Diagram

```
sysmaint (main script)
    │
    ├── lib/core/           # Core functionality
    │   ├── init.sh         # Initialization
    │   ├── detection.sh    # OS detection
    │   ├── logging.sh      # Logging
    │   └── error_handling.sh
    │
    ├── lib/platform/       # Platform-specific modules
    │   ├── detector.sh     # Auto-detects platform
    │   ├── base.sh         # Base class
    │   ├── debian.sh       # Debian/Ubuntu
    │   ├── redhat.sh       # Fedora/RHEL/Rocky/Alma/CentOS
    │   ├── arch.sh         # Arch Linux
    │   └── suse.sh         # openSUSE
    │
    ├── lib/maintenance/    # Maintenance operations
    │   ├── packages.sh     # Package operations
    │   ├── kernel.sh       # Kernel management
    │   ├── storage.sh      # Cache/cleanup
    │   ├── system.sh       # System operations
    │   └── security.sh     # Security audits
    │
    ├── lib/validation/     # Validation modules
    ├── lib/reporting/      # Output/reporting
    ├── lib/progress/       # Progress tracking
    └── lib/gui/            # Interactive interface
```

---

## Platform Module System

### Auto-Detection

The `detector.sh` module automatically identifies the OS and loads the appropriate platform module:

```bash
# Detection process
1. Read /etc/os-release
2. Parse ID and ID_LIKE
3. Match to platform family
4. Source platform-specific module
5. Fall back to base.sh if needed
```

### Platform Files

| File | Purpose | Supports |
|------|---------|----------|
| `base.sh` | Base class with defaults | All platforms |
| `debian.sh` | Debian/Ubuntu specifics | Ubuntu, Debian |
| `redhat.sh` | RedHat family specifics | Fedora, RHEL, Rocky, Alma, CentOS |
| `arch.sh` | Arch Linux specifics | Arch Linux |
| `suse.sh` | SUSE family specifics | openSUSE |

---

## Module Functions

Each platform module implements these functions:

| Function | Purpose | Default Behavior |
|----------|---------|------------------|
| `update_packages()` | Update system packages | OS-specific command |
| `clean_packages()` | Remove unused packages | OS-specific command |
| `clean_cache()` | Clear package cache | OS-specific command |
| `manage_kernels()` | Remove old kernels | Boot space check |
| `update_snaps()` | Update Snap packages | Check if snapd installed |
| `update_flatpaks()` | Update Flatpaks | Check if flatpak installed |
| `get_package_info()` | Get package count/name | Parse package DB |

---

## Benefits

### 1. Zero Breaking Changes

| Before | After |
|--------|-------|
| One monolithic script | Separate platform modules |
| Risk breaking all platforms | Only affects one OS family |
| Hard to test | Test in isolation |

### 2. Easy Maintenance

```
Fix for CentOS issue:
├── Edit lib/platform/redhat.sh
├── Test on CentOS only
├── Verify Ubuntu/Fedora still work
└── Commit with confidence
```

### 3. Graceful Degradation

```
If platform module fails:
1. Fall back to base.sh defaults
2. Log warning
3. Continue with available functionality
4. Don't crash entire script
```

---

## Adding a New Platform

### Step 1: Create Platform Module

```bash
# lib/platform/newdistro.sh
source_platform_base() {
    # Implement required functions
    update_packages() { command; }
    clean_packages() { command; }
    # ... etc
}
```

### Step 2: Update Detector

```bash
# lib/platform/detector.sh
# Add detection logic
case "$ID" in
    newdistro) source "$LIB_DIR/platform/newdistro.sh" ;;
esac
```

### Step 3: Test

```bash
# Test on new platform
./sysmaint --dry-run --verbose
```

---

## Core Modules

### Core (`lib/core/`)

| Module | Purpose |
|--------|---------|
| `init.sh` | Set up paths, colors, load modules |
| `detection.sh` | Detect OS, container, package manager |
| `logging.sh` | Log levels, output formatting |
| `error_handling.sh` | Error codes, cleanup on exit |

### Maintenance (`lib/maintenance/`)

| Module | Purpose |
|--------|---------|
| `packages.sh` | Package update, upgrade, removal |
| `kernel.sh` | Old kernel removal |
| `storage.sh` | Cache, temp file, journal cleanup |
| `system.sh` | System-level operations |
| `security.sh` | Permission checks, service validation |

### Validation (`lib/validation/`)

| Module | Purpose |
|--------|---------|
| `keys.sh` | GPG key validation |
| `repos.sh` | Repository integrity checks |
| `services.sh` | Service health checks |
| `security.sh` | Security audits |

### Reporting (`lib/reporting/`)

| Module | Purpose |
|--------|---------|
| `json.sh` | JSON output generation |
| `summary.sh` | Execution summary |
| `reboot.sh` | Reboot recommendations |

---

## Data Flow

```
User Command
    │
    ├──> init.sh (initialize)
    │       │
    │       └──> detection.sh (detect OS)
    │               │
    │               └──> detector.sh (load platform)
    │                       │
    │                       └──> debian.sh/redhat.sh/arch.sh/suse.sh
    │
    ├──> maintenance/*.sh (execute operations)
    │       │
    │       └──> Use platform module functions
    │
    ├──> reporting/*.sh (generate output)
    │
    └──> exit (cleanup, return code)
```

---

## Version: v1.0.0

**Document Version:** v1.0.0
**Project:** https://github.com/Harery/SYSMAINT
