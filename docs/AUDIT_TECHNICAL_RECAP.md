# 🔧 Technical Recap

**SYSMAINT — Comprehensive Technical Architecture Analysis**

---

## Table of Contents

- [System Overview](#system-overview)
- [Architecture](#architecture)
- [Component Layers](#component-layers)
- [Data Flows](#data-flows)
- [Dependency Graph](#dependency-graph)
- [Platform Abstraction](#platform-abstraction)
- [Execution Modes](#execution-modes)
- [State Management](#state-management)
- [Error Handling Strategy](#error-handling-strategy)
- [CI/CD Integration](#cicd-integration)

---

## System Overview

SYSMAINT is a **multi-distribution Linux system maintenance platform** built entirely in Bash 4.0+. The system provides unified package management, system cleanup, security auditing, and maintenance automation across 9 Linux distributions.

### Technical Specifications

| Aspect | Specification |
|--------|---------------|
| **Language** | Bash ≥4.0 (associative arrays, modern features) |
| **Main Script** | `sysmaint` (5,008 lines, 170KB) |
| **Library Modules** | 39 files, ~8,907 lines across 9 directories |
| **Platform Support** | 9 distributions, 4 OS families |
| **Package Managers** | 6 managers (APT, DNF, YUM, Pacman, Zypper, Snap, Flatpak) |
| **Test Coverage** | 32 test suites, 500+ tests |
| **Documentation** | 30+ markdown files, ~15,000 lines |

### Supported Platforms

```
DEBIAN FAMILY          REDHAT FAMILY          ARCH FAMILY           SUSE FAMILY
├── Ubuntu 22.04       ├── RHEL 9/10          ├── Arch Linux        ├── openSUSE Tumbleweed
├── Ubuntu 24.04       ├── Fedora 41           (Rolling)            (Rolling)
├── Debian 12          ├── Rocky Linux 9/10
└── Debian 13          ├── AlmaLinux 9
                       └── CentOS Stream 9
```

---

## Architecture

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           USER INTERACTION LAYER                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │ CLI Mode     │  │ TUI Mode     │  │ JSON Output  │  │ Subcommands  │   │
│  │ (--auto)     │  │ (--gui)      │  │ (--json)     │  │ (scanners)   │   │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘   │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────┴──────────────────────────────────────┐
│                          ORCHESTRATION LAYER                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │ Main Script  │  │ Lock Mgmt    │  │ Progress     │  │ Error        │   │
│  │ (sysmaint)   │  │ (lock.sh)    │  │ Tracking     │  │ Handling     │   │
│  │              │  │              │  │ (progress/)  │  │ (error_hndl) │   │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘   │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────┴──────────────────────────────────────┐
│                           MAINTENANCE LAYER                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │ Packages     │  │ Kernel       │  │ System       │  │ Storage      │   │
│  │ (packages.sh)│  │ (kernel.sh)  │  │ (system.sh)  │  │ (storage.sh) │   │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                       │
│  │ Snap         │  │ Flatpak      │  │ Firmware     │                       │
│  │ (snap.sh)    │  │ (flatpak.sh) │  │ (firmware.sh)│                       │
│  └──────────────┘  └──────────────┘  └──────────────┘                       │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────┴──────────────────────────────────────┐
│                           VALIDATION LAYER                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │ Repositories │  │ GPG Keys     │  │ Services     │  │ Security     │   │
│  │ (repos.sh)   │  │ (keys.sh)    │  │ (services.sh)│  │ (security.sh)│   │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘   │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────┴──────────────────────────────────────┐
│                        PLATFORM ABSTRACTION LAYER                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │ Debian       │  │ RedHat       │  │ Arch         │  │ SUSE         │   │
│  │ (debian.sh)  │  │ (redhat.sh)  │  │ (arch.sh)    │  │ (suse.sh)    │   │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                       │
│  │ Base Platform│  │ Platform     │  │ OS Families  │                       │
│  │ (base.sh)    │  │ Detector     │  │ (4 families) │                       │
│  └──────────────┘  └──────────────┘  └──────────────┘                       │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────┴──────────────────────────────────────┐
│                              CORE LAYER                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │ Init         │  │ Detection    │  │ Capabilities │  │ Logging      │   │
│  │ (init.sh)    │  │ (detection)  │  │ (caps.sh)    │  │ (logging.sh) │   │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Component Layers

### Layer 1: Core Infrastructure

```
┌─────────────────────────────────────────────────────────────────┐
│                     CORE INITIALIZATION                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. SCRIPT STARTUP (sysmaint:27-76)                            │
│     ├─ Strict mode: set -Eeuo pipefail                         │
│     ├─ DEBIAN_FRONTEND=noninteractive                          │
│     ├─ CI/CD detection (CI env var + TTY check)                │
│     ├─ Script directory resolution                            │
│     └─ LOG_DIR creation with early validation                 │
│                                                                 │
│  2. MODULE LOADING (sysmaint:77-215)                           │
│     ├─ Core modules (init, detection, logging, capabilities)   │
│     ├─ Progress modules (panel, estimates, profiling, parallel)│
│     ├─ Maintenance modules (7 modules)                         │
│     ├─ Validation modules (4 modules)                          │
│     ├─ Reporting modules (json, summary, reboot)              │
│     └─ GUI module (interface)                                  │
│                                                                 │
│  3. STATE INITIALIZATION (lib/core/init.sh)                    │
│     ├─ OS detection (/etc/os-release)                          │
│     ├─ Root privilege validation                              │
│     ├─ Platform module loading                                 │
│     ├─ State file creation (/var/run/sysmaint_state.json)     │
│     └─ Lock acquisition                                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Layer 2: Platform Abstraction

```
┌─────────────────────────────────────────────────────────────────┐
│                   PLATFORM DETECTION FLOW                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  START                                                          │
│   │                                                             │
│   ▼                                                             │
│  ┌─────────────────┐                                           │
│  │ Read /etc/      │                                           │
│  │ os-release      │                                           │
│  └────────┬────────┘                                           │
│           │                                                     │
│           ▼                                                     │
│  ┌──────────────────────────────────────────────────────┐      │
│  │ Parse ID and ID_LIKE fields                           │      │
│  │                                                       │      │
│  │ Examples:                                             │      │
│  │   Ubuntu: ID=ubuntu, ID_LIKE=debian                  │      │
│  │   RHEL:   ID=rhel, ID_LIKE=fedora                    │      │
│  │   Arch:   ID=arch (no ID_LIKE)                       │      │
│  └────────┬──────────────────────────────────────────────┘      │
│           │                                                     │
│    ┌──────┴──────┬──────────┬──────────┬──────────┐            │
│    │              │          │          │          │            │
│    ▼              ▼          ▼          ▼          ▼            │
│  ┌──────┐    ┌──────┐   ┌──────┐   ┌──────┐   ┌──────┐         │
│  │Debian│    │RedHat│   │ Arch │   │ SUSE │   │Other │         │
│  │Family│    │Family│   │Linux │   │Family│   │(Exit)│         │
│  └──┬───┘    └──┬───┘   └──┬───┘   └──┬───┘   └──────┘         │
│     │           │           │           │                       │
│     ▼           ▼           ▼           ▼                       │
│  ┌──────┐    ┌──────┐   ┌──────┐   ┌──────┐                    │
│  │Load  │    │Load  │   │Load  │   │Load  │                    │
│  │debian│    │redhat│   │ arch │   │ suse │                    │
│  │.sh   │    │.sh   │   │.sh   │   │.sh   │                    │
│  └──────┘    └──────┘   └──────┘   └──────┘                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Platform Module Interfaces

Each platform module implements standardized interfaces:

```bash
# Package Manager Operations (required)
package_update()          # Update package metadata
package_upgrade()         # Upgrade installed packages
package_cleanup()         # Clean package cache
package_list_orphans()    # List orphaned packages
package_remove_orphans()  # Remove orphaned packages

# Platform-Specific Operations (optional)
platform_pre_maintenance()   # Pre-maintenance hooks
platform_post_maintenance()  # Post-maintenance hooks
platform_detect_quirks()     # Detect platform-specific issues
```

---

## Data Flows

### Main Execution Flow

```
┌───────────────────────────────────────────────────────────────────┐
│                       MAIN EXECUTION FLOW                         │
└───────────────────────────────────────────────────────────────────┘

START
  │
  ▼
┌─────────────────────────────────────┐
│ 1. EARLY DISPATCH                   │
│     • Parse CLI arguments           │
│     • Subcommands? (scanners/profiles)│
│     • GUI mode? (--gui)             │
│     • Detection mode? (--detect)    │
│     • If early exit → END           │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│ 2. PRE-FLIGHT CHECKS               │
│     • require_root()                │
│     • check_os()                    │
│     • health_checks()               │
│     • Collect host profile          │
│     • Load platform detector        │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│ 3. CAPABILITY DETECTION             │
│     • Detect: snap, flatpak, fwupd  │
│     • Detect: docker, fstrim        │
│     • Detect: deborphan             │
│     • Desktop vs Server mode        │
│     • Log capabilities              │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│ 4. SIMULATE MODE?                  │
│     • If --simulate-upgrade         │
│     • Run safe dist-upgrade simulation│
│     • Emit summary and exit         │
└─────────────────┬───────────────────┘
                  │ (if NO)
                  ▼
┌─────────────────────────────────────┐
│ 5. CAPTURE METRICS                  │
│     • Disk usage (before)           │
│     • OS description                │
│     • Package count                 │
│     • Memory/swap stats             │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│ 6. EXECUTION MODE SELECTION         │
│     • PARALLEL_EXEC=true?           │
│       → execute_parallel() (DAG)   │
│     • Otherwise:                    │
│       → Sequential 24-phase flow    │
└─────────────────┬───────────────────┘
                  │
    ┌─────────────┴─────────────┐
    │                           │
    ▼                           ▼
┌─────────────┐         ┌─────────────┐
│ PARALLEL    │         │ SEQUENTIAL  │
│ MODE        │         │ MODE        │
│ (DAG-based) │         │ (24 phases) │
└──────┬──────┘         └──────┬──────┘
       │                      │
       └──────────┬───────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│ 7. POST-EXECUTION                  │
│     • reboot_if_required()          │
│     • Capture disk usage (after)    │
│     • Calculate disk saved          │
│     • check_zombie_processes()      │
│     • security_audit()              │
│     • truncate_log_if_needed()      │
│     • print_summary()               │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│ 8. EXIT WITH CODE                  │
│     • 0: Success                    │
│     • 1: General error              │
│     • 10: Repository failures      │
│     • 20: Missing APT keys          │
│     • 30: Failed services           │
│     • 100: Reboot required          │
└─────────────────┬───────────────────┘
                  │
                  ▼
                END
```

### Sequential Phase Flow

```
┌───────────────────────────────────────────────────────────────────┐
│                    24-PHASE SEQUENTIAL FLOW                       │
└───────────────────────────────────────────────────────────────────┘

PHASE 1:  clean_tmp
          └─> Temporary directory cleanup (/tmp, /var/tmp)

PHASE 2:  fix_broken_if_any
          └─> Fix broken package dependencies

PHASE 3:  validate_repos
          └─> Repository validation (HTTP, release files)

PHASE 4:  detect_missing_pubkeys
          └─> Detect missing GPG keys

PHASE 5:  fix_missing_pubkeys
          └─> Fix missing keys (if --fix-missing-keys)

PHASE 6:  kernel_status
          └─> Display current kernel status

PHASE 7:  apt_maintenance
          └─> APT update, upgrade, dist-upgrade

PHASE 8:  kernel_purge_phase
          └─> Purge old kernel packages

PHASE 9:  post_kernel_finalize
          └─> Post-kernel cleanup

PHASE 10: orphan_purge_phase
           └─> Remove orphan packages

PHASE 11: snap_maintenance
           └─> Snap package updates

PHASE 12: snap_cleanup_old
           └─> Remove old snap revisions

PHASE 13: snap_clear_cache
           └─> Clear snap cache

PHASE 14: flatpak_maintenance
           └─> Flatpak updates

PHASE 15: firmware_maintenance
           └─> Firmware updates via fwupd

PHASE 16: dns_maintenance
           └─> Clear DNS cache

PHASE 17: journal_maintenance
           └─> Vacuum systemd journal

PHASE 18: thumbnail_maintenance
           └─> Clear thumbnail cache

PHASE 19: browser_cache_phase
           └─> Browser cache cleanup

PHASE 20: crash_dump_purge
           └─> Remove crash dumps

PHASE 21: fstrim_phase
           └─> Filesystem TRIM (SSD optimization)

PHASE 22: drop_caches_phase
           └─> Drop kernel caches

PHASE 23: upgrade_finalize
           └─> Final upgrade phase

PHASE 24: check_failed_services
           └─> Check for failed systemd services

Each phase:
  • Records start/end timestamp
  • Updates status panel
  • Shows progress (dots/bar/spinner/adaptive)
  • Tracks disk delta
  • Logs to file and stdout
```

---

## Dependency Graph

### Module Loading Order (Critical!)

```
                    sysmaint (main)
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
   ┌─────────┐     ┌──────────┐     ┌──────────┐
   │  CORE   │     │ PROGRESS │     │   GUI    │
   │ MODULES │     │  MODULES │     │  MODULE  │
   └────┬────┘     └────┬─────┘     └────┬─────┘
        │               │                │
        └───────────────┴────────────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
   ┌─────────┐   ┌──────────┐   ┌──────────┐
   │MAINTEN  │   │VALIDATION│   │ REPORTING│
   │ MODULES │   │  MODULES │   │  MODULES │
   └────┬────┘   └────┬─────┘   └────┬─────┘
        │              │              │
        └──────────────┴──────────────┘
                       │
                       ▼
                 ┌──────────┐
                 │ PLATFORM │
                 │ MODULES  │
                 └──────────┘

LOADING SEQUENCE (sysmaint:77-215):

1. CORE (81-104):
   • init.sh          - OS detection, root checks, state management
   • detection.sh     - Package manager, init system detection
   • logging.sh       - log(), run(), truncate_log_if_needed()
   • capabilities.sh  - Capability detection, mode resolution
   • error_handling.sh- on_exit(), on_err(), cleanup handlers

2. PROGRESS (106-127):
   • panel.sh         - Progress UI (show_progress, status panel)
   • estimates.sh     - ETA calculations, EMA (exponential moving average)
   • profiling.sh     - Host profiling (CPU/RAM/network scaling)
   • parallel.sh      - DAG-based parallel execution engine

3. MAINTENANCE (129-165):
   • packages.sh      - APT operations, retry logic
   • kernel.sh        - Kernel purging, status
   • snap.sh          - Snap package maintenance
   • flatpak.sh       - Flatpak maintenance
   • firmware.sh      - fwupd firmware updates
   • system.sh        - DNS, journal, thumbnails, browser cache, tmp cleanup
   • storage.sh       - Crash dumps, fstrim, drop caches

4. VALIDATION (167-188):
   • repos.sh         - Repository validation
   • keys.sh          - GPG/APT key management
   • services.sh      - Service health checks
   • security.sh      - Security audits

5. REPORTING (190-206):
   • json.sh          - JSON output helpers
   • summary.sh       - Summary report generation
   • reboot.sh        - Reboot handling

6. GUI (208-214):
   • interface.sh     - TUI interface using dialog/whiptail
```

### Inter-Module Dependencies

```
┌─────────────────────────────────────────────────────────────┐
│              INTER-MODULE DEPENDENCIES                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Core Module Dependencies:                                  │
│  • init.sh → detection.sh (needs OS detection first)       │
│  • All modules → logging.sh (logging required everywhere)   │
│  • All modules → error_handling.sh (error handlers)        │
│                                                             │
│  Progress System Dependencies:                              │
│  • panel.sh → estimates.sh (needs timing data)             │
│  • estimates.sh → profiling.sh (needs host profile)        │
│  • parallel.sh → panel.sh (updates progress)               │
│                                                             │
│  Maintenance Dependencies:                                  │
│  • kernel.sh → packages.sh (needs package manager)         │
│  • snap.sh → capabilities.sh (check if snap available)     │
│  • flatpak.sh → capabilities.sh (check if flatpak avail)   │
│  • firmware.sh → capabilities.sh (check if fwupd avail)    │
│  • storage.sh → packages.sh (some storage ops use pkg mgr) │
│  • system.sh → (no external dependencies)                  │
│                                                             │
│  Validation Dependencies:                                   │
│  • repos.sh → packages.sh (uses package manager)           │
│  • keys.sh → packages.sh (uses APT for keys)               │
│  • services.sh → (no external dependencies)                │
│  • security.sh → services.sh (checks service health)       │
│                                                             │
│  Reporting Dependencies:                                    │
│  • json.sh → (no external dependencies)                    │
│  • summary.sh → json.sh (generates JSON summary)           │
│  • reboot.sh → (no external dependencies)                  │
│                                                             │
│  GUI Dependencies:                                          │
│  • interface.sh → panel.sh (displays progress)             │
│  • interface.sh → summary.sh (displays summary)            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Platform Abstraction

### OS Family Hierarchy

```
┌─────────────────────────────────────────────────────────────────┐
│                    OS FAMILY HIERARCHY                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  BASE PLATFORM (lib/platform/base.sh)                           │
│  ├─ Default implementations of all package manager operations   │
│  ├─ Fallback for unsupported platforms                          │
│  └─ Common helper functions                                    │
│                                                                 │
│  PLATFORM DETECTOR (lib/platform/detector.sh)                   │
│  ├─ Reads /etc/os-release                                      │
│  ├─ Parses ID and ID_LIKE fields                               │
│  ├─ Selects appropriate platform module                        │
│  └─ Sources platform-specific code                             │
│                                                                 │
│  ┌─────────────────────────────────────────────────────┐       │
│  │             DEBIAN FAMILY (debian.sh)               │       │
│  │   ├─ Ubuntu 22.04, 24.04                            │       │
│  │   ├─ Debian 12, 13                                  │       │
│  │   ├─ Package Manager: APT                           │       │
│  │   ├─ Keyring: /usr/share/keyrings/                  │       │
│  │   └─ Orphan detection: deborphan                   │       │
│  └─────────────────────────────────────────────────────┘       │
│                                                                 │
│  ┌─────────────────────────────────────────────────────┐       │
│  │             REDHAT FAMILY (redhat.sh)               │       │
│  │   ├─ RHEL 9, 10                                     │       │
│  │   ├─ Fedora 41                                      │       │
│  │   ├─ Rocky Linux 9, 10                              │       │
│  │   ├─ AlmaLinux 9                                    │       │
│  │   ├─ CentOS Stream 9                               │       │
│  │   ├─ Package Manager: DNF (fallback: YUM)           │       │
│  │   └─ Keyring: /etc/pki/rpm-gpg/                     │       │
│  └─────────────────────────────────────────────────────┘       │
│                                                                 │
│  ┌─────────────────────────────────────────────────────┐       │
│  │               ARCH FAMILY (arch.sh)                 │       │
│  │   ├─ Arch Linux (rolling)                           │       │
│  │   ├─ Package Manager: pacman                        │       │
│  │   ├─ Mirrorlist: /etc/pacman.d/mirrorlist           │       │
│  │   ├─ Keyring: pacman-key                            │       │
│  │   └─ AUR support (via yay/paru)                     │       │
│  └─────────────────────────────────────────────────────┘       │
│                                                                 │
│  ┌─────────────────────────────────────────────────────┐       │
│  │               SUSE FAMILY (suse.sh)                 │       │
│  │   ├─ openSUSE Tumbleweed (rolling)                  │       │
│  │   ├─ Package Manager: zypper                        │       │
│  │   ├─ Keyring: /usr/share/rpm-gpg/                   │       │
│  │   └─ Exit code 127 quirk workaround                 │       │
│  └─────────────────────────────────────────────────────┘       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Package Manager Abstraction

```
┌─────────────────────────────────────────────────────────────────┐
│              PACKAGE MANAGER ABSTRACTION LAYER                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  lib/package_manager.sh (451 lines)                             │
│  ├─ Package manager auto-detection                              │
│  ├─ Unified interface for all package managers                  │
│  └─ Lazy initialization pattern                                 │
│                                                                 │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐       │
│  │    APT        │  │    DNF/YUM    │  │   Pacman      │       │
│  │  (Debian)     │  │  (RedHat)     │  │   (Arch)      │       │
│  └───────────────┘  └───────────────┘  └───────────────┘       │
│                                                                 │
│  Common Operations:                                            │
│  ├─ pkg_update()       - Update package metadata               │
│  ├─ pkg_upgrade()      - Upgrade installed packages            │
│  ├─ pkg_dist_upgrade() - Distribution upgrade                  │
│  ├─ pkg_cleanup()      - Clean package cache                   │
│  ├─ pkg_autoremove()   - Remove unused packages                │
│  ├─ pkg_install()      - Install specific package              │
│  ├─ pkg_remove()       - Remove specific package               │
│  └─ pkg_list_orphans() - List orphaned packages                │
│                                                                 │
│  Extended Package Managers:                                    │
│  ├─ Snap       (snap.sh)    - Universal package format         │
│  ├─ Flatpak    (flatpak.sh) - Desktop application packaging    │
│  └─ Firmware   (firmware.sh)- fwupd firmware updates           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Execution Modes

### Mode Selection Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    EXECUTION MODE SELECTION                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  START → Parse CLI Arguments                                   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────┐       │
│  │ Check for Early Exit Modes                          │       │
│  │                                                     │       │
│  │ • --help        → Show usage and exit               │       │
│  │ • --version     → Show version and exit             │       │
│  │ • --detect      → Show detection report and exit    │       │
│  │ • --gui/--tui   → Launch GUI mode and re-exec       │       │
│  │ • scanners      → Run scanners subcommand           │       │
│  │ • profiles      → Run profiles subcommand           │       │
│  └─────────────────────────────────────────────────────┘       │
│                                                                 │
│  ┌─────────────────────────────────────────────────────┐       │
│  │ Check for Special Modes                             │       │
│  │                                                     │       │
│  │ • --dry-run          → Read-only simulation mode     │       │
│  │ • --simulate-upgrade → Safe upgrade simulation       │       │
│  │ • --json             → JSON output mode              │       │
│  │ • --quiet            → Minimal output mode           │       │
│  │ • --verbose          → Verbose output mode           │       │
│  └─────────────────────────────────────────────────────┘       │
│                                                                 │
│  ┌─────────────────────────────────────────────────────┐       │
│  │ Check for Automation Mode                           │       │
│  │                                                     │       │
│  │ • CI env var = true                                 │       │
│  │ • NONINTERACTIVE = true                             │       │
│  │ • AUTO_MODE = true                                  │       │
│  │ • ASSUME_YES = true                                 │       │
│  │                                                     │       │
│  │ → Set all auto-confirm flags                        │       │
│  │ → Disable interactive prompts                       │       │
│  └─────────────────────────────────────────────────────┘       │
│                                                                 │
│  ┌─────────────────────────────────────────────────────┐       │
│  │ Check for Execution Mode                            │       │
│  │                                                     │       │
│  │ • PARALLEL_EXEC = true → execute_parallel()         │       │
│  │ • Otherwise           → Sequential 24-phase flow    │       │
│  └─────────────────────────────────────────────────────┘       │
│                                                                 │
│  ┌─────────────────────────────────────────────────────┐       │
│  │ Check for Progress Mode                             │       │
│  │                                                     │       │
│  │ • PROGRESS_MODE=none     → No progress display      │       │
│  │ • PROGRESS_MODE=dots     → Dot progress (...)       │       │
│  │ • PROGRESS_MODE=countdown→ Countdown (10...1)       │       │
│  │ • PROGRESS_MODE=bar      → Progress bar [=====>    ]│       │
│  │ • PROGRESS_MODE=spinner  → Spinner (/|\-)          │       │
│  │ • PROGRESS_MODE=adaptive → 3-line status panel      │       │
│  └─────────────────────────────────────────────────────┘       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Parallel Execution Mode

```
┌─────────────────────────────────────────────────────────────────┐
│                    PARALLEL EXECUTION (DAG)                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  execute_parallel() - lib/progress/parallel.sh                 │
│                                                                 │
│  Dependency Graph Structure:                                    │
│                                                                 │
│            [clean_tmp]                                          │
│                 │                                               │
│                 ▼                                               │
│        [fix_broken_if_any]                                      │
│                 │                                               │
│                 ▼                                               │
│    ┌──────────┴──────────┐                                     │
│    │                     │                                     │
│    ▼                     ▼                                     │
│ [validate_repos]   [detect_missing_pubkeys]                    │
│    │                     │                                     │
│    └──────────┬──────────┘                                     │
│               │                                                │
│               ▼                                                │
│        [fix_missing_pubkeys]                                   │
│               │                                                │
│               ▼                                                │
│      ┌───────────────┐                                        │
│      │   apt_maint   │                                        │
│      └───────┬───────┘                                        │
│              │                                                │
│     ┌────────┴────────┬──────────────┬─────────────┐          │
│     │                 │              │             │          │
│     ▼                 ▼              ▼             ▼          │
│ [kernel_status] [kernel_purge] [orphan_purge] [snap_maint]    │
│     │                 │              │             │          │
│     └────────┬────────┴──────────────┴─────────────┘          │
│              │                                                │
│              ▼                                                │
│    [post_kernel_finalize]                                     │
│              │                                                │
│     ┌────────┴────────┬──────────────┬─────────────┐          │
│     │                 │              │             │          │
│     ▼                 ▼              ▼             ▼          │
│ [snap_cleanup] [flatpak_maint] [firmware] [dns_maint]         │
│     │                 │              │             │          │
│     └────────┬────────┴──────────────┴─────────────┘          │
│              │                                                │
│              ▼                                                │
│    ┌─────────────────────────────┐                           │
│    │   System Cleanup Phases    │                           │
│    │  (journal, thumbnails,     │                           │
│    │   browser, crash, fstrim)  │                           │
│    └─────────────────┬───────────┘                           │
│                      │                                       │
│                      ▼                                       │
│              [upgrade_finalize]                              │
│                      │                                       │
│                      ▼                                       │
│              [check_failed_services]                         │
│                      │                                       │
│                      ▼                                       │
│                    END                                        │
│                                                                 │
│  Features:                                                     │
│  • Phase-based execution with dependencies                    │
│  • Parallel execution of independent phases                   │
│  • Progress tracking for all active phases                    │
│  • Error handling and rollback                                │
│  • Disk delta tracking per phase                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## State Management

### State Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      STATE MANAGEMENT                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. STATE FILE (/var/run/sysmaint_state.json)                  │
│     ├─ Created during initialization                           │
│     ├─ Updated after each phase                                │
│     ├─ Contains:                                               │
│     │   • Current phase                                        │
│     │   • Phase timings (start, end, duration)                 │
│     │   • Disk usage deltas                                    │
│     │   • Exit codes                                           │
│     │   • Host profile (CPU, RAM, network)                     │
│     └─ Deleted on cleanup                                      │
│                                                                 │
│  2. LOCK FILE (/var/run/sysmaint.lock)                         │
│     ├─ Acquired during initialization                          │
│     ├─ Prevents concurrent execution                           │
│     ├─ Contains:                                               │
│     │   • PID of owning process                                │
│     │   • Start timestamp                                      │
│     │   • Run ID                                               │
│     └─ Released on exit (via trap)                             │
│                                                                 │
│  3. LOG FILE (/var/log/sysmaint_<RUN_ID>.log)                  │
│     ├─ Created early in initialization                         │
│     ├─ Dual output:                                            │
│     │   • Log file (full details)                              │
│     │   • Stdout/stderr (user-visible)                         │
│     ├─ Truncated if > LOG_MAX_SIZE_MB                          │
│     └─ Archived after run                                      │
│                                                                 │
│  4. PROGRESS STATE                                             │
│     ├─ Stored in associative arrays:                           │
│     │   • PHASE_TIMINGS[phase]=duration                        │
│     │   • PHASE_EST_EMA[phase]=exponential_moving_average      │
│     │   • DISK_DELTAS[phase]=bytes_freed                       │
│     └─ Updated by progress tracking system                     │
│                                                                 │
│  5. CONFIGURATION STATE                                        │
│     ├─ Environment variables (with defaults)                   │
│     ├─ CLI flags (override environment)                        │
│     └─ Runtime state (capabilities, mode, flags)               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### State Transitions

```
┌─────────────────────────────────────────────────────────────────┐
│                    STATE TRANSITIONS                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [IDLE]                                                        │
│     │ acquire_lock()                                           │
│     ▼                                                           │
│  [INITIALIZING]                                                │
│     │ detect OS, load platform, check capabilities            │
│     ▼                                                           │
│  [READY]                                                       │
│     │ simulate mode?                                          │
│     ├─YES─→ [SIMULATING] → emit summary → [EXIT]              │
│     │                                                           │
│     ├─NO──                                                      │
│     ▼                                                            │
│  [EXECUTING]                                                   │
│     │ execute phases (parallel or sequential)                  │
│     │ update state after each phase                            │
│     ▼                                                           │
│  [FINALIZING]                                                  │
│     │ check services, security audit, summary                 │
│     ▼                                                           │
│  [EXITING]                                                     │
│     │ cleanup, release lock, set exit code                    │
│     ▼                                                           │
│  [TERMINATED]                                                  │
│                                                                 │
│  Error Handling:                                               │
│  • Any phase can fail → [ERROR]                               │
│  • [ERROR] → log error, cleanup, exit with code                │
│  • Critical errors: exit immediately                           │
│  • Non-critical errors: log and continue (|| true)             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Error Handling Strategy

### Error Handling Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   ERROR HANDLING STRATEGY                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. STRICT MODE (sysmaint:27)                                  │
│     set -Eeuo pipefail                                         │
│     ├─ -E: ERR trap inherits                                   │
│     ├─ -e: Exit on error                                      │
│     ├─ -u: Exit on undefined variable                          │
│     └─ -o pipefail: Exit on pipe failure                       │
│                                                                 │
│  2. TRAP HANDLERS (lib/core/error_handling.sh)                 │
│     ├─ on_exit() - Called on any exit (success or failure)     │
│     │   ├─ Release lock file                                  │
│     │   ├─ Stop status panel                                  │
│     │   ├─ Truncate log if needed                             │
│     │   └─ Cleanup temporary files                            │
│     │                                                          │
│     ├─ on_err() - Called on error (trap ERR)                   │
│     │   ├─ Log error with timestamp                           │
│     │   ├─ Capture error context                              │
│     │   └─ Trigger cleanup                                   │
│     │                                                          │
│     └─ signal handlers - SIGINT, SIGTERM                       │
│         ├─ Graceful shutdown                                  │
│         └─ Cleanup before exit                                │
│                                                                 │
│  3. EXIT CODE STRATEGY                                         │
│     ├─ 0   - Success                                          │
│     ├─ 1   - General error                                    │
│     ├─ 2   - Lock exists (another instance running)           │
│     ├─ 3   - Unsupported distribution                         │
│     ├─ 4   - Permission denied                                │
│     ├─ 5   - Package manager error                            │
│     ├─ 10  - Repository validation failures                  │
│     ├─ 20  - Missing APT public keys                          │
│     ├─ 30  - Failed systemd services                          │
│     ├─ 75  - Lock acquisition timeout                         │
│     └─ 100 - Reboot required                                  │
│                                                                 │
│  4. ERROR PROPAGATION                                          │
│     ├─ Critical errors: Exit immediately                       │
│     ├─ Non-critical errors: || true to continue                │
│     ├─ Validation errors: Log and skip phase                  │
│     └─ Network errors: Retry with exponential backoff         │
│                                                                 │
│  5. ERROR RECOVERY                                             │
│     ├─ Network failures: Retry (3 attempts, 2-30s backoff)     │
│     ├─ Lock timeout: Wait up to 3 seconds                      │
│     ├─ Package manager failures: Attempt repair                │
│     ├─ Service failures: Log and continue                      │
│     └─ Kernel purge failures: Log and keep current kernel      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Error Handling Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    ERROR HANDLING FLOW                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [PHASE START]                                                  │
│       │                                                         │
│       │ Record phase start timestamp                           │
│       ▼                                                         │
│  [EXECUTE PHASE]                                                │
│       │                                                         │
│       ├─SUCCESS─→ [PHASE COMPLETE]                             │
│       │             │ Record phase end timestamp              │
│       │             │ Update state file                       │
│       │             │ Continue to next phase                 │
│       │                                                          │
│       └─FAILURE──→ [ERROR HANDLER]                             │
│                     │ Log error details                       │
│                     │ Increment error counter                │
│                     │                                        │
│                     ├─CRITICAL─→ [IMMEDIATE EXIT]            │
│                     │             │ on_exit() cleanup        │
│                     │             │ Exit with error code     │
│                     │                                        │
│                     └─NON-CRITICAL→ [LOG & CONTINUE]         │
│                                   │ || true to continue      │
│                                   │ Record error in state    │
│                                   │ Continue to next phase   │
│                                                                 │
│  [POST-EXECUTION ERROR CHECK]                                   │
│       │                                                         │
│       ├─ Repository failures? → Exit code 10                   │
│       ├─ Missing keys?        → Exit code 20                   │
│       ├─ Failed services?     → Exit code 30                   │
│       ├─ Reboot required?     → Exit code 100                  │
│       └─ Otherwise            → Exit code 0                    │
│                                                                 │
│  [CLEANUP & EXIT]                                              │
│       │                                                         │
│       ▼                                                         │
│  [on_exit()]                                                   │
│       ├─ Release lock file                                      │
│       ├─ Stop status panel                                      │
│       ├─ Truncate log if oversized                             │
│       └─ Exit with determined code                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## CI/CD Integration

### CI/CD Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    CI/CD PIPELINE FLOW                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [PUSH/PR TO MAIN]                                             │
│         │                                                       │
│         ▼                                                       │
│  ┌───────────────────────┐                                    │
│  │   ci.yml Triggered    │                                    │
│  │   (.github/workflows) │                                    │
│  └───────────┬───────────┘                                    │
│              │                                               │
│              ▼                                               │
│  ┌───────────────────────┐                                    │
│  │  ShellCheck Job       │  • Lint all shell scripts          │
│  │  (severity: warning)  │  • Check for issues                │
│  └───────────┬───────────┘  • Exit on critical errors        │
│              │                                               │
│              ▼                                               │
│  ┌───────────────────────┐                                    │
│  │   Test Suite Job      │  • Install dependencies           │
│  │   (6 test suites)     │  • Run smoke tests                │
│  │                       │  • Run function tests             │
│  │                       │  • Run security tests             │
│  │                       │  • Run mode tests                 │
│  │                       │  • Run feature tests              │
│  │                       │  • Run GitHub Actions tests       │
│  └───────────┬───────────┘  • Collect results                │
│              │               • Upload artifacts               │
│              ▼                                               │
│  ┌───────────────────────┐                                    │
│  │   Results Upload      │  • JSON results (30 days)         │
│  │   (Artifacts)         │  • Test logs (7 days)             │
│  └───────────┬───────────┘                                    │
│              │                                               │
│              ├─[IF TAG v*.*.*]──────────────────┐            │
│              │                                  │            │
│              ▼                                  ▼            │
│  ┌───────────────────┐              ┌─────────────────────┐  │
│  │ [Push to main]    │              │ [Tag: v*.*.*]       │  │
│  │     │             │              │      │              │  │
│  │     ▼             │              │      ▼              │  │
│  │ docker.yml        │              │ release.yml          │  │
│  │ (Build images)    │              │ (Create release)     │  │
│  │ • Ubuntu          │              │ • Attach binaries    │  │
│  │ • Debian          │              │ • Generate notes     │  │
│  │ • Fedora          │              │ • Publish to GitHub  │  │
│  │ • Multi-arch      │              └─────────────────────┘  │
│  │ (amd64/arm64)     │                                    │
│  │ • Push to GHCR    │                                    │
│  └───────────────────┘                                    │
│              │                                               │
│              └─[IF PATH FILTERS MATCH]──────────────┐        │
│                                                     │        │
│                                                     ▼        │
│                                      ┌─────────────────────┐ │
│                                      │ test-matrix.yml     │ │
│                                      │ (13 OS variants)    │ │
│                                      │                     │ │
│                                      │ • Ubuntu 22.04, 24.04│ │
│                                      │ • Debian 12, 13     │ │
│                                      │ • Fedora 41         │ │
│                                      │ • RHEL 9, 10        │ │
│                                      │ • Rocky 9, 10       │ │
│                                      │ • Alma 9            │ │
│                                      │ • CentOS Stream 9   │ │
│                                      │ • Arch rolling      │ │
│                                      │ • openSUSE Tumbleweed│ │
│                                      │                     │ │
│                                      │ • Run smoke tests    │ │
│                                      │ • Run OS family tests│ │
│                                      │ • Upload results    │ │
│                                      │ • Aggregate report  │ │
│                                      └─────────────────────┘ │
│                                                     │        │
│                                                     ▼        │
│                                      ┌─────────────────────┐ │
│                                      │ GITHUB_STEP_SUMMARY │ │
│                                      │ • Test coverage     │ │
│                                      │ • Pass rates        │ │
│                                      │ • Artifacts list    │ │
│                                      └─────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Docker Multi-Architecture Build

```
┌─────────────────────────────────────────────────────────────────┐
│              DOCKER MULTI-ARCHITECTURE BUILD                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  docker.yml Workflow                                           │
│                                                                 │
│  [Trigger: Push to main, PR, Tag, Manual]                      │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────────────────────────────────────────┐          │
│  │     Matrix: variant × architecture              │          │
│  │                                                  │          │
│  │  ┌─────────┬─────────────────────────────────┐   │          │
│  │  │ Variant │ Architectures                  │   │          │
│  │  ├─────────┼─────────────────────────────────┤   │          │
│  │  │ Ubuntu  │ linux/amd64, linux/arm64       │   │          │
│  │  │ Debian  │ linux/amd64, linux/arm64       │   │          │
│  │  │ Fedora  │ linux/amd64, linux/arm64       │   │          │
│  │  │ Default │ linux/amd64, linux/arm64       │   │          │
│  │  └─────────┴─────────────────────────────────┘   │          │
│  └──────────────────────────────────────────────────┘          │
│                         │                                      │
│                         ▼                                      │
│  ┌──────────────────────────────────────────────────┐          │
│  │       Each Build Job (parallel)                  │          │
│  │                                                  │          │
│  │  1. Setup QEMU for multi-arch support           │          │
│  │  2. Setup Docker Buildx                         │          │
│  │  3. Login to GitHub Container Registry          │          │
│  │  4. Build with cache:                           │          │
│  │     • type=registry,ref=ghcr.io/harery/sysmaint│          │
│  │     • scope=ubuntu|debian|fedora|default       │          │
│  │  5. Metadata:                                   │          │
│  │     • Tags: version, branch, latest            │          │
│  │     • Labels: OCI-compliant                    │          │
│  │  6. Build and push (if not PR)                 │          │
│  │  7. Verify build                               │          │
│  └──────────────────────────────────────────────────┘          │
│                         │                                      │
│                         ▼                                      │
│  ┌──────────────────────────────────────────────────┐          │
│  │       Summary Job                                │          │
│  │       • Aggregate build status                  │          │
│  │       • Publish to GITHUB_STEP_SUMMARY          │          │
│  │       • List all images pushed                  │          │
│  └──────────────────────────────────────────────────┘          │
│                                                                 │
│  Images Published:                                              │
│  • ghcr.io/harery/sysmaint:ubuntu                               │
│  • ghcr.io/harery/sysmaint:debian                               │
│  • ghcr.io/harery/sysmaint:fedora                               │
│  • ghcr.io/harery/sysmaint:latest                               │
│  • ghcr.io/harery/sysmaint:{version}                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Deployment Architecture

### Kubernetes Deployment Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│              KUBERNETES DEPLOYMENT OPTIONS                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. CRONJOB (Recommended for Maintenance)                      │
│     ┌───────────────────────────────────────────┐              │
│     │ Schedule: Weekly, Daily, Monthly          │              │
│     │                                            │              │
│     │ • Weekly:  "0 2 * * 0" (Sun 2 AM)        │              │
│     │ • Daily:   "0 3 * * *" (Daily 3 AM)      │              │
│     │ • Monthly: "0 2 1 * *" (1st of month)    │              │
│     │                                            │              │
│     │ Features:                                  │              │
│     │ • hostPID: true (system access)           │              │
│     │ • Privileged: true (required)             │              │
│     │ • Volume: /host (read-only mount)         │              │
│     │ • Concurrency: Forbid                     │              │
│     │ • BackoffLimit: 0 (no retries)           │              │
│     └───────────────────────────────────────────┘              │
│                                                                 │
│  2. DAEMONSET (Cluster-Wide Maintenance)                       │
│     ┌───────────────────────────────────────────┐              │
│     │ Runs on: All nodes                       │              │
│     │                                            │              │
│     │ Features:                                  │              │
│     │ • Tolerates control-plane taints          │              │
│     │ • Tolerates all tainted nodes             │              │
│     │ • Command: sleep infinity (on-demand)     │              │
│     │ • Manual execution via kubectl exec       │              │
│     └───────────────────────────────────────────┘              │
│                                                                 │
│  3. DEPLOYMENT (Debugging/Testing Only)                        │
│     ┌───────────────────────────────────────────┐              │
│     │ Replicas: 1                                │              │
│     │                                            │              │
│     │ Features:                                  │              │
│     │ • Command: sleep 3600 (keep alive)        │              │
│     │ • For debugging and manual testing        │              │
│     │ • NOT recommended for production          │              │
│     └───────────────────────────────────────────┘              │
│                                                                 │
│  RBAC Configuration:                                            │
│  ┌───────────────────────────────────────────┐                  │
│  │ ServiceAccount: sysmaint                  │                  │
│  │                                            │                  │
│  │ Role (sysmaint):                           │                  │
│  │ • get, list, watch pods                   │                  │
│  │ • get, list, watch jobs, cronjobs         │                  │
│  │                                            │                  │
│  │ ClusterRole (sysmaint-privileged):        │                  │
│  │ • get, list, watch nodes (cluster-wide)   │                  │
│  │                                            │                  │
│  │ Bindings:                                  │                  │
│  │ • RoleBinding: sysmaint → sysmaint Role   │                  │
│  │ • ClusterRoleBinding: sysmaint → Cluster  │                  │
│  └───────────────────────────────────────────┘                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Native Packaging (Debian/RPM)

```
┌─────────────────────────────────────────────────────────────────┐
│              NATIVE PACKAGING ARCHITECTURE                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  DEBIAN PACKAGE (deb)                                          │
│  ┌───────────────────────────────────────────┐                  │
│  │ Build System: debhelper-compat 13        │                  │
│  │                                           │                  │
│  │ Installed Files:                          │                  │
│  │ • /usr/bin/sysmaint (main script)         │                  │
│  │ • /usr/share/doc/sysmaint/ (docs)         │                  │
│  │ • lib/ (library modules)                  │                  │
│  │ • systemd units (service + timer)         │                  │
│  │ • man pages                               │                  │
│  │ • shell completions (bash, zsh)           │                  │
│  │                                           │                  │
│  │ Dependencies:                              │                  │
│  │ • bash (>= 4.2)                          │                  │
│  │ • apt                                    │                  │
│  │ • systemd                                │                  │
│  │ • Recommends: fwupd, snapd, dialog       │                  │
│  └───────────────────────────────────────────┘                  │
│                                                                 │
│  RPM PACKAGE (RedHat Family)                                    │
│  ┌───────────────────────────────────────────┐                  │
│  │ Build System: rpmbuild                    │                  │
│  │                                           │                  │
│  │ Installed Files:                          │                  │
│  │ • /usr/sbin/sysmaint (main script)        │                  │
│  │ • /usr/lib/sysmaint/ (library modules)    │                  │
│  │ • systemd units (service + timer)         │                  │
│  │ • man pages                               │                  │
│  │ • shell completions (bash, zsh)           │                  │
│  │                                           │                  │
│  │ Dependencies:                              │                  │
│  │ • bash >= 4.2                             │                  │
│  │ • systemd                                 │                  │
│  │ • dnf                                     │                  │
│  │ • Recommends: fwupd, dialog               │                  │
│  │                                           │                  │
│  │ Scriptlets:                                │                  │
│  │ • %post: Enable timer on install          │                  │
│  │ • %preun: Stop/disable timer on uninstall │                  │
│  │ • %postun: Reload systemd on upgrade      │                  │
│  └───────────────────────────────────────────┘                  │
│                                                                 │
│  SYSTEMD TIMER                                                  │
│  ┌───────────────────────────────────────────┐                  │
│  │ sysmaint.timer                             │                  │
│  │ • OnCalendar: Sun *-*-* 03:00:00         │                  │
│  │ • Persistent: true (runs if missed)       │                  │
│  │ • RandomizedDelaySec: 15m (jitter)       │                  │
│  │ • WantedBy: timers.target                 │                  │
│  └───────────────────────────────────────────┘                  │
│                                                                 │
│  SYSTEMD SERVICE                                                │
│  ┌───────────────────────────────────────────┐                  │
│  │ sysmaint.service                          │                  │
│  │ • Type: oneshot                           │                  │
│  │ • ExecStart: /usr/bin/sysmaint --auto    │                  │
│  │ • Security hardening:                     │                  │
│  │   - NoNewPrivileges=true                  │                  │
│  │   - PrivateTmp=true                       │                  │
│  │   - ProtectSystem=full                    │                  │
│  │   - ProtectHome=true                      │                  │
│  │   - ProtectControlGroups=true             │                  │
│  │   - LockPersonality=true                  │                  │
│  │   - RestrictRealtime=true                 │                  │
│  │   - RestrictSUIDSGID=true                 │                  │
│  │   - SystemCallArchitectures=native        │                  │
│  └───────────────────────────────────────────┘                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Summary

### Key Architectural Strengths

1. **Modular Design**: Clear separation of concerns across 9 library directories
2. **Platform Abstraction**: Multi-distro support via platform-specific modules
3. **Package Manager Abstraction**: Unified interface for 6 package managers
4. **Flexible Execution**: Sequential 24-phase flow or parallel DAG-based execution
5. **Comprehensive Testing**: 32 test suites with 500+ tests
6. **CI/CD Integration**: GitHub Actions with multi-OS testing (13 variants)
7. **Container Support**: Multi-architecture Docker images (amd64/arm64)
8. **Kubernetes Ready**: CronJob, DaemonSet, and Deployment manifests
9. **Native Packaging**: Debian and RPM packages with systemd integration
10. **Progress Tracking**: Adaptive progress system with EMA timing estimates

### Technical Complexity

- **Main Script**: 5,008 lines of well-structured Bash code
- **Library Modules**: 39 files, ~8,907 lines across 9 directories
- **Platform Support**: 9 distributions across 4 OS families
- **Package Managers**: 6 managers (APT, DNF, YUM, Pacman, Zypper, Snap, Flatpak)
- **Test Coverage**: 32 test suites, professional-grade infrastructure
- **Documentation**: 30+ markdown files, ~15,000 lines
- **Deployment**: Docker, Kubernetes, Helm, systemd, native packages

### Execution Paths

1. **Interactive CLI**: `sudo sysmaint` (default mode with prompts)
2. **Automated Mode**: `CI=true sudo sysmaint` (non-interactive)
3. **GUI Mode**: `sudo sysmaint --gui` (TUI with dialog)
4. **JSON Mode**: `sudo sysmaint --json` (machine-readable output)
5. **Simulation Mode**: `sudo sysmaint --dry-run` (read-only preview)
6. **Subcommands**: `sysmaint scanners`, `sysmaint profiles`

### Data Flow Summary

```
USER INPUT (CLI flags + environment variables)
    ↓
EARLY DISPATCH (subcommands, GUI, detection)
    ↓
PRE-FLIGHT CHECKS (root, OS, health)
    ↓
CAPABILITY DETECTION (available tools)
    ↓
METRICS CAPTURE (before state)
    ↓
EXECUTION (24 phases or parallel DAG)
    ↓
POST-EXECUTION (reboot, summary, security)
    ↓
EXIT WITH CODE (0, 1, 10, 20, 30, 100)
```

---

**Document Version:** 1.0.0
**Generated:** 2026-01-15
**Project:** https://github.com/Harery/SYSMAINT
**License:** MIT
