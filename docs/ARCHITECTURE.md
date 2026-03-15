# 🏗️ Architecture

**OCTALUM-PULSE Modular Platform Architecture — System Design Document**

---

## Table of Contents

- [Overview](#overview)
- [Directory Structure](#directory-structure)
- [Component Layers](#component-layers)
- [Platform Abstraction](#platform-abstraction)
- [Data Flow](#data-flow)
- [Exit Codes](#exit-codes)
- [Module Dependencies](#module-dependencies)

---

## Overview

OCTALUM-PULSE is built on a **modular, layered architecture** that enables cross-platform compatibility while maintaining distribution-specific optimizations. The design follows these principles:

| Principle | Description |
|-----------|-------------|
| **Separation of Concerns** | Each module has a single, well-defined responsibility |
| **Platform Abstraction** | Distribution-specific code isolated in platform modules |
| **Error Resilience** | Fail-safe operations with comprehensive error handling |
| **Extensibility** | Easy to add new platforms or maintenance operations |
| **Testability** | All modules independently testable with 500+ tests |

---

## Directory Structure

```
pulse/
├── pulse                      # Main entry point (5,008 lines)
│
├── lib/                          # Core library modules
│   ├── core/                     # Core functionality
│   │   ├── init.sh              # Initialization & OS detection
│   │   ├── capabilities.sh      # Capability checks (sudo, commands)
│   │   └── lock.sh              # File locking mechanism
│   │
│   ├── platform/                 # Platform-specific modules
│   │   ├── debian.sh            # Debian/Ubuntu support
│   │   ├── redhat.sh            # RHEL/Fedora/Rocky/Alma/CentOS
│   │   ├── arch.sh              # Arch Linux support
│   │   └── suse.sh              # openSUSE support
│   │
│   ├── os_families/              # OS family overrides
│   │   ├── debian_family.sh     # Debian-family defaults
│   │   └── redhat_family.sh     # RedHat-family defaults
│   │
│   ├── maintenance/              # Maintenance operations
│   │   ├── packages.sh          # Package management abstraction
│   │   ├── cleanup.sh           # System cleanup operations
│   │   └── kernels.sh           # Kernel management
│   │
│   ├── validation/               # Security & system validation
│   │   ├── security.sh          # Security auditing
│   │   ├── services.sh          # Service validation
│   │   └── repos.sh             # Repository validation
│   │
│   ├── progress/                 # Progress tracking
│   │   ├── panel.sh             # Progress panel display
│   │   ├── estimates.sh         # Time estimates
│   │   └── parallel.sh          # Parallel execution
│   │
│   ├── reporting/                # Output & reporting
│   │   ├── json.sh              # JSON output generation
│   │   ├── summary.sh           # Summary reporting
│   │   └── logging.sh           # Logging utilities
│   │
│   └── gui/                      # User interfaces
│       ├── cli.sh               # CLI interface
│       ├── tui.sh               # Terminal UI (dialog/whiptail)
│       └── colors.sh            # Terminal colors
│
├── tests/                        # Test suite (500+ tests)
│   ├── test_suite_smoke.sh      # Smoke tests
│   ├── test_suite_security.sh   # Security tests
│   ├── test_suite_performance.sh # Performance tests
│   └── ...                      # Additional test suites
│
├── packaging/                    # Packaging configurations
│   ├── systemd/                 # Systemd service files
│   ├── rpm/                     # RPM packaging
│   └── completion/              # Shell completion scripts
│
└── docs/                         # Documentation
    ├── PRD.md                   # Product Requirements
    ├── ARCHITECTURE.md          # This document
    └── ...                      # Additional docs
```

---

## Component Layers

```
┌─────────────────────────────────────────────────────────────┐
│                     USER INTERFACE LAYER                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   CLI Mode   │  │   TUI Mode   │  │  JSON Output │      │
│  │  (cli.sh)    │  │  (tui.sh)    │  │  (json.sh)   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                    ORCHESTRATION LAYER                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Main Script │  │    Locking   │  │   Progress   │      │
│  │  (pulse)  │  │  (lock.sh)   │  │  (progress/) │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                    MAINTENANCE LAYER                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Packages   │  │    Cleanup   │  │    Kernels   │      │
│  │ (packages.sh)│  │  (cleanup.sh)│  │ (kernels.sh) │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                   VALIDATION LAYER                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Security   │  │   Services   │  │  Repositories│      │
│  │(security.sh) │  │(services.sh) │  │  (repos.sh)  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                  PLATFORM ABSTRACTION LAYER                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │    Debian    │  │    RedHat    │  │     Arch     │      │
│  │ (debian.sh)  │  │  (redhat.sh) │  │  (arch.sh)   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                      CORE LAYER                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │     Init     │  │   Capabilities│  │  OS Detect   │      │
│  │  (init.sh)   │  │(capabilities)│  │  (init.sh)   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### Layer Descriptions

| Layer | Responsibility | Modules |
|-------|----------------|---------|
| **User Interface** | User interaction modes | CLI, TUI, JSON output |
| **Orchestration** | Coordination & flow control | Main script, locking, progress |
| **Maintenance** | Core maintenance operations | Packages, cleanup, kernels |
| **Validation** | Security & system checks | Security audit, services, repos |
| **Platform** | Distribution-specific logic | Debian, RedHat, Arch, SUSE |
| **Core** | Initialization & detection | OS detection, capabilities |

---

## Platform Abstraction

### Platform Detection Flow

```
┌─────────────────┐
│  pulse start │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Detect OS      │
│  /etc/os-release│
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐ ┌────────────┐
│ Debian?│ │ RedHat?    │
└───┬────┘ └────┬───────┘
    │          │
    ▼          ▼
┌────────┐ ┌────────────┐
│Load    │ │Load        │
│Debian  │ │RedHat      │
│Module  │ │Module      │
└────────┘ └────────────┘
```

### Platform Modules

| Platform | Module | Supported Distributions |
|----------|--------|--------------------------|
| **Debian** | `lib/platform/debian.sh` | Ubuntu, Debian |
| **RedHat** | `lib/platform/redhat.sh` | RHEL, Fedora, Rocky, Alma, CentOS |
| **Arch** | `lib/platform/arch.sh` | Arch Linux |
| **SUSE** | `lib/platform/suse.sh` | openSUSE |

### Package Manager Abstraction

Each platform module implements a **standard interface**:

```bash
# Package manager operations (must be implemented)
package_update()      # Update package metadata
package_upgrade()     # Upgrade installed packages
package_cleanup()     # Clean package cache
package_list_orphans() # List orphaned packages
package_remove_orphans() # Remove orphaned packages
```

---

## Data Flow

### Execution Flow

```
┌───────────────────────────────────────────────────────────────┐
│                         START                                  │
└───────────────────────────┬───────────────────────────────────┘
                            │
                            ▼
┌───────────────────────────────────────────────────────────────┐
│  1. INITIALIZATION                                             │
│     • Acquire lock file                                        │
│     • Detect operating system                                  │
│     • Load platform-specific module                            │
│     • Check capabilities (sudo, required commands)             │
└───────────────────────────┬───────────────────────────────────┘
                            │
                            ▼
┌───────────────────────────────────────────────────────────────┐
│  2. USER INTERFACE SELECTION                                   │
│     • Parse command-line arguments                             │
│     • Select mode (CLI, TUI, JSON)                             │
│     • Initialize display components                            │
└───────────────────────────┬───────────────────────────────────┘
                            │
                            ▼
┌───────────────────────────────────────────────────────────────┐
│  3. MAINTENANCE OPERATIONS                                     │
│     • Package management (update, upgrade, cleanup)            │
│     • System cleanup (logs, cache, temp, kernels)              │
│     • Security audit (permissions, services, repos)            │
└───────────────────────────┬───────────────────────────────────┘
                            │
                            ▼
┌───────────────────────────────────────────────────────────────┐
│  4. REPORTING                                                  │
│     • Generate summary                                         │
│     • Output JSON (if requested)                               │
│     • Display results to user                                  │
└───────────────────────────┬───────────────────────────────────┘
                            │
                            ▼
┌───────────────────────────────────────────────────────────────┐
│  5. CLEANUP & EXIT                                             │
│     • Release lock file                                        │
│     • Set exit code based on results                           │
│     • Exit                                                     │
└───────────────────────────────────────────────────────────────┘
```

---

## Exit Codes

OCTALUM-PULSE uses standardized exit codes for scripting and automation:

| Code | Name | Description | Action Required |
|------|------|-------------|-----------------|
| **0** | SUCCESS | All operations completed successfully | None |
| **1** | GENERAL_ERROR | Unspecified error occurred | Check logs |
| **2** | LOCK_EXISTS | Another instance is running | Wait or kill existing process |
| **3** | UNSUPPORTED_DISTRO | Distribution not supported | Check supported platforms |
| **4** | PERMISSION_DENIED | Insufficient privileges | Run with sudo |
| **5** | PACKAGE_MANAGER_ERROR | Package operation failed | Check package manager logs |
| **10** | REPO_ISSUES | Repository problems detected | Check repository configuration |
| **20** | MISSING_KEYS | GPG keys missing | Import missing keys |
| **30** | FAILED_SERVICES | Services failed to start | Check service status |
| **75** | LOCK_TIMEOUT | Could not acquire lock | Check for hung processes |
| **100** | REBOOT_REQUIRED | System reboot required | Reboot system |

### Using Exit Codes in Scripts

```bash
#!/bin/bash

# Run pulse
sudo pulse --auto --quiet
EXIT_CODE=$?

# Handle exit codes
case $EXIT_CODE in
    0)  echo "Success" ;;
    1)  echo "General error - check logs" ;;
    2)  echo "Another instance running" ;;
    3)  echo "Unsupported distribution" ;;
    4)  echo "Permission denied" ;;
    100) echo "Reboot required" ;;
    *)   echo "Unknown exit code: $EXIT_CODE" ;;
esac

exit $EXIT_CODE
```

---

## Module Dependencies

```
                   ┌──────────────┐
                   │   pulse   │
                   │   (main)     │
                   └──────┬───────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
┌───────────────┐  ┌──────────────┐  ┌──────────────┐
│  lib/core/   │  │ lib/gui/     │  │lib/reporting/│
│               │  │              │  │              │
│ • init.sh     │  │ • cli.sh     │  │ • json.sh    │
│ • lock.sh     │  │ • tui.sh     │  │ • summary.sh │
│ • capabilities│  │ • colors.sh  │  │ • logging.sh │
└───────────────┘  └──────────────┘  └──────────────┘
        │                 │                 │
        └─────────────────┼─────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
┌───────────────┐  ┌──────────────┐  ┌──────────────┐
│lib/maintenance│  │lib/validation│  │lib/progress/ │
│               │  │              │  │              │
│ • packages.sh │  │ • security.sh│  │ • panel.sh   │
│ • cleanup.sh  │  │ • services.sh│  │ • estimates  │
│ • kernels.sh  │  │ • repos.sh   │  │ • parallel   │
└───────┬───────┘  └──────────────┘  └──────────────┘
        │
        ▼
┌───────────────┐
│lib/platform/  │
│               │
│ • debian.sh   │
│ • redhat.sh   │
│ • arch.sh     │
│ • suse.sh     │
└───────────────┘
```

---

## Security Architecture

### Permission Model

```
┌─────────────────────────────────────────────────────────────┐
│                     PERMISSION MODEL                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    │
│  │   Regular   │    │     Sudo    │    │     Root     │    │
│  │    User     │───▶│   (required)│───▶│   (minimal)  │    │
│  │             │    │             │    │   usage)     │    │
│  └─────────────┘    └─────────────┘    └─────────────┘    │
│         │                  │                    │          │
│         │                  │                    │          │
│         ▼                  ▼                    ▼          │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    │
│  │  --dry-run  │    │  --auto     │    │  --upgrade  │    │
│  │  --version  │    │  --cleanup  │    │  --cleanup  │    │
│  │  --help     │    │  --gui      │    │  --security │    │
│  └─────────────┘    └─────────────┘    └─────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Security Controls

| Control | Implementation | Protection |
|---------|----------------|-------------|
| **Input Validation** | Parameter sanitization in all modules | Command injection |
| **Least Privilege** | Minimal sudo requirements | Privilege escalation |
| **Lock File** | `/var/run/pulse.lock` | Concurrent execution |
| **Dry-Run Mode** | Read-only simulation | Unintended changes |
| **Audit Logging** | JSON output trail | Compliance & debugging |

---

## Extensibility

### Adding a New Platform

To add support for a new Linux distribution:

1. **Create platform module:**
   ```bash
   lib/platform/newdistro.sh
   ```

2. **Implement required functions:**
   ```bash
   package_update() { :; }
   package_upgrade() { :; }
   package_cleanup() { :; }
   package_list_orphans() { :; }
   package_remove_orphans() { :; }
   ```

3. **Add OS detection:**
   ```bash
   # In lib/core/init.sh
   *"newdistro"*) PLATFORM="newdistro" ;;
   ```

4. **Add tests:**
   ```bash
   tests/test_suite_newdistro.sh
   ```

### Adding a New Maintenance Operation

1. **Create module in `lib/maintenance/`:**
   ```bash
   lib/maintenance/new_operation.sh
   ```

2. **Implement function:**
   ```bash
   run_new_operation() {
       # Your logic here
   }
   ```

3. **Add to main execution flow:**
   ```bash
   # In pulse main script
   if [[ "$RUN_NEW_OPERATION" == "true" ]]; then
       run_new_operation
   fi
   ```

4. **Add CLI flag:**
   ```bash
   --new-operation) RUN_NEW_OPERATION=true ;;
   ```

5. **Add tests:**
   ```bash
   tests/test_suite_new_operation.sh
   ```

---

## Performance Considerations

### Optimization Strategies

| Component | Optimization | Impact |
|-----------|--------------|--------|
| **Package Updates** | Parallel metadata fetching | 30% faster |
| **Cleanup** | Targeted directory scanning | 50% faster |
| **Progress** | Async status updates | Better UX |
| **JSON Output** | Streaming generation | Lower memory |

### Resource Limits

| Resource | Limit | Rationale |
|----------|-------|-----------|
| **Memory** | <100 MB | Minimal footprint |
| **Runtime** | <5 min | Acceptable window |
| **Disk I/O** | Moderate | Avoid system impact |
| **Network** | Package managers only | No external calls |

---

**Document Version:** v1.0.0
**Last Updated:** 2025-12-28
**Project:** https://github.com/Harery/OCTALUM-PULSE
