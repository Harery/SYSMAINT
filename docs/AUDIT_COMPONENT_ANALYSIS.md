# SYSMAINT — Component Analysis

**Complete Catalog of All Project Components, Roles, and Coupling**

---

## Overview

This document provides a comprehensive analysis of every component in the SYSMAINT project, cataloging files by their roles, responsibilities, interdependencies, and identifying unused or duplicated code. This analysis serves as the foundation for understanding the codebase architecture and identifying refactoring opportunities.

---

## Table of Contents

1. [Main Entry Point](#1-main-entry-point)
2. [Core Infrastructure](#2-core-infrastructure)
3. [Platform Abstraction Layer](#3-platform-abstraction-layer)
4. [Maintenance Operations](#4-maintenance-operations)
5. [Validation System](#5-validation-system)
6. [Reporting and Output](#6-reporting-and-output)
7. [User Interface Layer](#7-user-interface-layer)
8. [Progress Tracking](#8-progress-tracking)
9. [Package Management](#9-package-management)
10. [Test Infrastructure](#10-test-infrastructure)
11. [Deployment and Integration](#11-deployment-and-integration)
12. [Documentation](#12-documentation)
13. [Cross-Cutting Concerns](#13-cross-cutting-concerns)
14. [Duplicated Code Analysis](#14-duplicated-code-analysis)
15. [Unused Code Analysis](#15-unused-code-analysis)
16. [Coupling Analysis](#16-coupling-analysis)

---

## 1. Main Entry Point

### 1.1 `sysmaint` (5,008 lines, 170KB)

**Role:** Orchestration hub and primary execution controller

**Responsibilities:**
- Command-line interface parsing (50+ flags)
- Environment variable initialization and override handling
- Module dependency resolution and loading
- Subcommand dispatch (scanners, profiles, GUI mode)
- Pre-flight checks (root privileges, OS support, health checks)
- Capability detection (snap, flatpak, fwupd, docker, etc.)
- Phase orchestration (24 sequential phases or parallel DAG execution)
- State management (run ID, log files, state files)
- Lock management (concurrency control)
- Error handling and exit code management
- Post-execution cleanup and reporting

**Coupling:**
- **High Coupling:** Loads all library modules in strict dependency order
- **Circular Dependency Risk:** None (modular loading prevents this)
- **Interface Stability:** Stable (well-defined environment variable contracts)

**Key Interfaces:**
```bash
# Public Interface
sysmaint [--auto] [--gui] [--dry-run] [--distro=<distro>] [options]

# Environment Variables (Configuration Layer)
SYSMAINT_LOG_DIR, AUTO_REBOOT, DRY_RUN, JSON_SUMMARY, ASSUME_YES

# Exit Codes (Contract with callers)
0=Success, 1=Error, 10=RepoFail, 20=MissingKeys, 30=FailedServices,
75=LockTimeout, 100=RebootRequired
```

**Dependencies (Load Order):**
1. Core: `init.sh`, `detection.sh`, `logging.sh`, `capabilities.sh`, `error_handling.sh`
2. Progress: `panel.sh`, `estimates.sh`, `profiling.sh`, `parallel.sh`
3. Maintenance: `packages.sh`, `kernel.sh`, `snap.sh`, `flatpak.sh`, `firmware.sh`, `system.sh`, `storage.sh`
4. Validation: `repos.sh`, `keys.sh`, `services.sh`, `security.sh`
5. Reporting: `json.sh`, `summary.sh`, `reboot.sh`
6. GUI: `interface.sh`

**Issues Identified:**
- **Size:** 5,008 lines is large; consider splitting phase orchestration into separate module
- **Configuration:** Variables scattered (lines 354-500+); could consolidate
- **Error Masking:** Some phases use `|| true` which may hide failures (e.g., `orphan_purge_phase`)

---

## 2. Core Infrastructure

### 2.1 `lib/core/init.sh` (207 lines)

**Role:** System initialization and environment validation

**Responsibilities:**
- OS family detection (Debian, RedHat, Arch, SUSE)
- Root privilege validation
- State directory creation and management
- Log directory initialization
- Detection override handling (for testing)

**Coupling:**
- **Low Coupling:** Self-contained validation
- **No Dependencies:** Foundation layer (loaded first)

**Key Functions:**
- `detect_os_family()` - OS family detection
- `require_root()` - Root privilege validation
- `initialize_state()` - State directory setup
- `create_directories()` - Directory creation

**Dependencies:** None (foundation layer)

---

### 2.2 `lib/core/detection.sh` (557 lines)

**Role:** Auto-detection of system capabilities and configuration

**Responsibilities:**
- Package manager detection (APT, DNF, YUM, Pacman, Zypper)
- Init system detection (systemd, sysvinit, openrc)
- Distribution detection (Ubuntu, Debian, Fedora, RHEL, CentOS, Rocky, Alma, Arch, openSUSE)
- Manual override support for testing
- Detection result caching

**Coupling:**
- **Medium Coupling:** Interfaces with platform-specific modules
- **Upstream Dependency:** `init.sh` (for OS family context)

**Key Functions:**
- `detect_package_manager()` - PM detection with fallbacks
- `detect_init_system()` - Init system detection
- `detect_distro()` - Distribution detection
- `apply_overrides()` - Manual override application

**Dependencies:** `init.sh`

---

### 2.3 `lib/core/logging.sh` (112 lines)

**Role:** Centralized logging infrastructure

**Responsibilities:**
- Structured logging with timestamps
- Dual output (log file + stdout/stderr)
- Color-coded messages by type
- Log file rotation (truncation)

**Coupling:**
- **Low Coupling:** Utility functions used by all modules
- **No Dependencies:** Self-contained

**Key Functions:**
- `log()` - Main logging function
- `run()` - Execute and log command
- `truncate_log_if_needed()` - Log rotation

**Dependencies:** None

---

### 2.4 `lib/core/capabilities.sh` (85 lines)

**Role:** System capability detection

**Responsibilities:**
- Detect optional tools (snap, flatpak, fwupd, docker, fstrim, deborphan)
- Desktop vs server mode detection
- Capability availability logging

**Coupling:**
- **Low Coupling:** Read-only detection
- **No Dependencies:** Self-contained

**Key Functions:**
- `detect_capabilities()` - Main capability detection
- `is_desktop()` - Desktop environment detection
- `check_tool()` - Tool availability check

**Dependencies:** None

---

### 2.5 `lib/core/error_handling.sh` (83 lines)

**Role:** Error handling and cleanup orchestration

**Responsibilities:**
- Trap-based exit handlers
- Lock file cleanup
- State file cleanup
- Zombie process detection
- Exit code management

**Coupling:**
- **High Coupling:** Coordinates cleanup across all modules
- **Upstream Dependencies:** `logging.sh`, `init.sh`

**Key Functions:**
- `on_exit()` - Exit trap handler
- `on_err()` - Error trap handler
- `cleanup()` - Resource cleanup
- `check_zombie_processes()` - Zombie detection

**Dependencies:** `logging.sh`, `init.sh`

---

## 3. Platform Abstraction Layer

### 3.1 Platform Detection

#### `lib/platform/detector.sh` (149 lines)

**Role:** Platform detection and module loading orchestration

**Responsibilities:**
- Auto-detect current platform (Debian, RedHat, Arch, SUSE)
- Load platform-specific module
- Provide platform-aware utility functions
- Platform quirk handling

**Coupling:**
- **Medium Coupling:** Loads platform-specific modules dynamically
- **Upstream Dependencies:** `init.sh`, `detection.sh`

**Key Functions:**
- `detect_and_load_platform()` - Platform detection and loading
- `get_platform_module()` - Platform module resolution
- `platform_aware()` - Platform-aware execution wrapper

**Dependencies:** `init.sh`, `detection.sh`

---

#### `lib/platform/base.sh` (232 lines)

**Role:** Base platform with default implementations

**Responsibilities:**
- Default package manager operations
- Default service management operations
- Default system operations
- Fallback implementations for all platforms

**Coupling:**
- **Low Coupling:** Provides default implementations
- **No Dependencies:** Self-contained defaults

**Key Functions:**
- `base_pkg_update()` - Default package update
- `base_pkg_upgrade()` - Default package upgrade
- `base_service_restart()` - Default service restart
- `base_get_init_system()` - Default init system detection

**Dependencies:** None

---

#### `lib/platform/debian.sh` (86 lines)

**Role:** Debian/Ubuntu platform implementation

**Responsibilities:**
- Debian-specific package operations
- Debian-specific service operations
- Debian-specific quirks (auto-dependencies)

**Coupling:**
- **Low Coupling:** Extends base.sh
- **Upstream Dependency:** `base.sh`

**Key Functions:**
- `platform_pkg_update()` - APT update
- `platform_pkg_upgrade()` - APT upgrade
- `platform_service_restart()` - systemd restart

**Dependencies:** `base.sh`

**Platform Quirks:**
- Automatic dependency resolution (no manual intervention needed)
- Simplest platform implementation

---

#### `lib/platform/redhat.sh` (198 lines)

**Role:** RedHat/Fedora/CentOS/Rocky/Alma platform implementation

**Responsibilities:**
- RedHat-specific package operations (DNF/YUM fallbacks)
- RedHat-specific service operations
- Subscription manager handling (RHEL-specific)

**Coupling:**
- **Medium Coupling:** Handles DNF/YUM fallbacks
- **Upstream Dependency:** `base.sh`

**Key Functions:**
- `platform_pkg_update()` - DNF/YUM update
- `platform_pkg_upgrade()` - DNF/YUM upgrade
- `platform_service_restart()` - systemd restart
- `handle_subscription_manager()` - RHEL subscription

**Dependencies:** `base.sh`

**Platform Quirks:**
- DNF primary, YUM fallback (older systems)
- Subscription manager on RHEL

---

#### `lib/platform/arch.sh` (167 lines)

**Role:** Arch Linux platform implementation

**Responsibilities:**
- Arch-specific package operations (pacman)
- Arch-specific service operations
- Arch quirk handling (missing flock/bc in base images)

**Coupling:**
- **Medium Coupling:** Handles Arch-specific quirks
- **Upstream Dependency:** `base.sh`

**Key Functions:**
- `platform_pkg_update()` - Pacman -Sy
- `platform_pkg_upgrade()` - Pacman -Su
- `platform_service_restart()` - systemd restart
- `handle_arch_quirks()` - Missing utilities workaround

**Dependencies:** `base.sh`

**Platform Quirks:**
- Base images missing `flock` and `bc` utilities
- Requires explicit package installation (util-linux, bc)
- Kernel naming: `linux-*` packages

---

#### `lib/platform/suse.sh` (185 lines)

**Role:** SUSE/openSUSE platform implementation

**Responsibilities:**
- SUSE-specific package operations (zypper)
- SUSE-specific service operations
- SUSE quirk handling (exit code 127)

**Coupling:**
- **Medium Coupling:** Handles SUSE-specific quirks
- **Upstream Dependency:** `base.sh`

**Key Functions:**
- `platform_pkg_update()` - Zypper refresh
- `platform_pkg_upgrade()` - Zypper dup
- `platform_service_restart()` - systemd restart
- `handle_suse_quirks()` - Exit code 127 workaround

**Dependencies:** `base.sh`

**Platform Quirks:**
- Exit code 127 requires special handling
- Zypper uses different syntax than APT/DNF

---

### 3.2 OS Family Abstractions

#### `lib/os_families/debian_family.sh` (179 lines)

**Role:** Debian/Ubuntu family operations

**Responsibilities:**
- Debian-specific package operations
- Orphaned package detection (deborphan)
- APT-specific operations

**Coupling:**
- **Low Coupling:** Debian-specific utilities
- **No Dependencies:** Self-contained

**Key Functions:**
- `debian_pkg_operations()` - APT operations
- `debian_find_orphans()` - Orphan detection
- `debian_clean_cache()` - APT cache cleanup

**Dependencies:** None

---

#### `lib/os_families/redhat_family.sh` (305 lines)

**Role:** RedHat/Fedora/CentOS/Rocky/Alma family operations

**Responsibilities:**
- RedHat-specific package operations
- DNF/YUM operations
- Subscription management

**Coupling:**
- **Medium Coupling:** Handles multiple package managers
- **No Dependencies:** Self-contained

**Key Functions:**
- `redhat_pkg_operations()` - DNF/YUM operations
- `redhat_clean_cache()` - DNF/YUM cache cleanup
- `handle_subscription()` - RHEL subscription

**Dependencies:** None

---

#### `lib/os_families/arch_family.sh` (392 lines)

**Role:** Arch Linux family operations

**Responsibilities:**
- Arch-specific package operations (pacman, AUR)
- Mirror list management
- Arch-specific system operations

**Coupling:**
- **Low Coupling:** Arch-specific utilities
- **No Dependencies:** Self-contained

**Key Functions:**
- `arch_pkg_operations()` - Pacman operations
- `arch_update_mirrorlist()` - Mirror list update
- `arch_clean_cache()` - Pacman cache cleanup

**Dependencies:** None

---

#### `lib/os_families/suse_family.sh` (348 lines)

**Role:** SUSE/openSUSE family operations

**Responsibilities:**
- SUSE-specific package operations (zypper)
- SUSE-specific system operations

**Coupling:**
- **Low Coupling:** SUSE-specific utilities
- **No Dependencies:** Self-contained

**Key Functions:**
- `suse_pkg_operations()` - Zypper operations
- `suse_clean_cache()` - Zypper cache cleanup

**Dependencies:** None

---

## 4. Maintenance Operations

### 4.1 `lib/maintenance/packages.sh` (357 lines)

**Role:** Package management operations abstraction

**Responsibilities:**
- Package update/upgrade orchestration
- Retry logic with exponential backoff
- Lock management (wait_for_pkg_managers)
- APT-specific operations (fix-broken, autoremove)
- Network resilience (retry on failure)

**Coupling:**
- **High Coupling:** Interfaces with platform layer
- **Upstream Dependencies:** `platform_utils.sh`, `package_manager.sh`

**Key Functions:**
- `apt_maintenance()` - APT update, upgrade, dist-upgrade
- `wait_for_pkg_managers()` - Lock acquisition
- `fix_broken_if_any()` - Fix broken packages
- `pkg_update()` - Package update wrapper
- `pkg_upgrade()` - Package upgrade wrapper

**Dependencies:** `platform_utils.sh`, `package_manager.sh`

**Issues Identified:**
- Name collision: `pkg_update()` and `pkg_upgrade()` also exist in `package_manager.sh`

---

### 4.2 `lib/maintenance/kernel.sh` (216 lines)

**Role:** Kernel management and purging

**Responsibilities:**
- Kernel status reporting
- Old kernel purging (keep N latest)
- Post-kernel cleanup
- Kernel-specific validations

**Coupling:**
- **Medium Coupling:** Platform-specific kernel operations
- **Upstream Dependencies:** `platform_utils.sh`, `package_manager.sh`

**Key Functions:**
- `kernel_status()` - Kernel status report
- `kernel_purge_phase()` - Old kernel purging
- `post_kernel_finalize()` - Post-kernel cleanup

**Dependencies:** `platform_utils.sh`, `package_manager.sh`

**Platform-Specific Behavior:**
- Debian/Ubuntu: `linux-*` packages
- RedHat/Fedora: `kernel-*` packages
- Arch: `linux` and `linux-lts` packages

---

### 4.3 `lib/maintenance/snap.sh` (172 lines)

**Role:** Snap package management

**Responsibilities:**
- Snap update operations
- Old snap revision cleanup
- Snap cache clearing
- Snap availability detection

**Coupling:**
- **Low Coupling:** Optional feature (check if snap installed)
- **Upstream Dependency:** `capabilities.sh`

**Key Functions:**
- `snap_maintenance()` - Snap updates
- `snap_cleanup_old()` - Remove old revisions
- `snap_clear_cache()` - Clear snap cache

**Dependencies:** `capabilities.sh`

**Optional Feature:** Only runs if `snap` command is detected

---

### 4.4 `lib/maintenance/flatpak.sh` (99 lines)

**Role:** Flatpak package management

**Responsibilities:**
- Flatpak update operations (user and system scope)
- Flatpak availability detection

**Coupling:**
- **Low Coupling:** Optional feature (check if flatpak installed)
- **Upstream Dependency:** `capabilities.sh`

**Key Functions:**
- `flatpak_maintenance()` - Flatpak updates

**Dependencies:** `capabilities.sh`

**Optional Feature:** Only runs if `flatpak` command is detected

---

### 4.5 `lib/maintenance/firmware.sh` (53 lines)

**Role:** Firmware updates via fwupd

**Responsibilities:**
- Firmware update operations
- Firmware availability detection

**Coupling:**
- **Low Coupling:** Optional feature (check if fwupdmgr installed)
- **Upstream Dependency:** `capabilities.sh`

**Key Functions:**
- `firmware_maintenance()` - Firmware updates

**Dependencies:** `capabilities.sh`

**Optional Feature:** Only runs if `fwupdmgr` command is detected

---

### 4.6 `lib/maintenance/system.sh` (311 lines)

**Role:** System-level maintenance operations

**Responsibilities:**
- Temporary directory cleanup
- DNS cache clearing
- Journal vacuuming
- Thumbnail cache clearing
- Browser cache cleanup

**Coupling:**
- **Medium Coupling:** Desktop-specific operations (thumbnails, browser cache)
- **Upstream Dependency:** `capabilities.sh`

**Key Functions:**
- `clean_tmp()` - Temporary directory cleanup
- `dns_maintenance()` - DNS cache clearing
- `journal_maintenance()` - Journal vacuuming
- `thumbnail_maintenance()` - Thumbnail cache clearing
- `browser_cache_phase()` - Browser cache cleanup

**Dependencies:** `capabilities.sh`

**Desktop vs Server:**
- Desktop mode: Runs all operations
- Server mode: Skips thumbnail and browser cache cleanup

---

### 4.7 `lib/maintenance/storage.sh` (159 lines)

**Role:** Storage optimization and cleanup

**Responsibilities:**
- Crash dump removal
- Filesystem TRIM (fstrim)
- Kernel cache dropping

**Coupling:**
- **Low Coupling:** Optional operations
- **Upstream Dependency:** `capabilities.sh`

**Key Functions:**
- `crash_dump_purge()` - Crash dump removal
- `fstrim_phase()` - Filesystem TRIM
- `drop_caches_phase()` - Kernel cache dropping

**Dependencies:** `capabilities.sh`

**Optional Feature:**
- fstrim: Only runs if `fstrim` command is detected
- Crash dumps: Only if directory exists

---

## 5. Validation System

### 5.1 `lib/validation/repos.sh` (122 lines)

**Role:** Repository validation

**Responsibilities:**
- Repository HTTP accessibility checks
- Repository release file validation
- Repository latency measurement

**Coupling:**
- **Medium Coupling:** Platform-specific repository formats
- **Upstream Dependencies:** `platform_utils.sh`, `package_manager.sh`

**Key Functions:**
- `validate_repos()` - Main validation function
- `check_repo_http()` - HTTP accessibility
- `check_repo_release_file()` - Release file validation
- `measure_repo_latency()` - Latency measurement

**Dependencies:** `platform_utils.sh`, `package_manager.sh`

---

### 5.2 `lib/validation/keys.sh` (148 lines)

**Role:** GPG/APT public key management

**Responsibilities:**
- Missing GPG key detection
- GPG key import operations
- Key server configuration

**Coupling:**
- **Medium Coupling:** Platform-specific key management
- **Upstream Dependencies:** `platform_utils.sh`, `package_manager.sh`

**Key Functions:**
- `detect_missing_pubkeys()` - Detect missing keys
- `fix_missing_pubkeys()` - Import missing keys
- `configure_keyserver()` - Key server configuration

**Dependencies:** `platform_utils.sh`, `package_manager.sh`

---

### 5.3 `lib/validation/services.sh` (68 lines)

**Role:** System service health validation

**Responsibilities:**
- Failed service detection (systemd)
- Zombie process detection

**Coupling:**
- **Low Coupling:** Read-only service checks
- **No Dependencies:** Self-contained

**Key Functions:**
- `check_failed_services()` - Failed service detection
- `check_zombie_processes()` - Zombie process detection

**Dependencies:** None

---

### 5.4 `lib/validation/security.sh` (110 lines)

**Role:** Security validation and auditing

**Responsibilities:**
- Permission checks
- Security health checks
- Audit operations

**Coupling:**
- **Low Coupling:** Read-only security checks
- **No Dependencies:** Self-contained

**Key Functions:**
- `security_audit()` - Main security audit
- `check_permissions()` - Permission validation
- `check_security_health()` - Security health check

**Dependencies:** None

---

## 6. Reporting and Output

### 6.1 `lib/reporting/json.sh` (35 lines)

**Role:** JSON output generation

**Responsibilities:**
- JSON summary creation
- JSON validation via jq

**Coupling:**
- **Low Coupling:** Output generation only
- **No Dependencies:** Self-contained

**Key Functions:**
- `generate_json_summary()` - JSON summary generation

**Dependencies:** None

---

### 6.2 `lib/reporting/summary.sh` (354 lines)

**Role:** Summary report generation

**Responsibilities:**
- Text summary generation
- JSON summary integration
- System metrics collection
- Disk usage reporting
- Recommendation generation

**Coupling:**
- **Medium Coupling:** Aggregates data from all modules
- **Upstream Dependencies:** All maintenance and validation modules

**Key Functions:**
- `print_summary()` - Main summary output
- `collect_system_metrics()` - Metrics collection
- `calculate_disk_saved()` - Disk savings calculation
- `generate_recommendations()` - Recommendation engine

**Dependencies:** All maintenance and validation modules

---

### 6.3 `lib/reporting/reboot.sh` (23 lines)

**Role:** Reboot requirement handling

**Responsibilities:**
- Reboot requirement detection
- Reboot notification

**Coupling:**
- **Low Coupling:** Simple flag check
- **No Dependencies:** Self-contained

**Key Functions:**
- `reboot_if_required()` - Conditional reboot
- `set_reboot_required()` - Set reboot flag

**Dependencies:** None

---

## 7. User Interface Layer

### 7.1 `lib/gui/interface.sh` (786 lines)

**Role:** Terminal User Interface (TUI) implementation

**Responsibilities:**
- Dialog-based menu system
- Progress bar display
- Confirmation dialogs
- Interactive option selection
- Modern 2026 UI/UX design

**Coupling:**
- **Medium Coupling:** Requires dialog/whiptail
- **No Dependencies:** Self-contained UI logic

**Key Functions:**
- `launch_gui_mode()` - Main TUI entry point
- `show_main_menu()` - Main menu display
- `show_options_menu()` - Options configuration menu
- `show_progress_dialog()` - Progress display
- `confirm_action()` - Confirmation dialog

**Dependencies:** dialog (or whiptail as fallback)

**UI Features:**
- Modern 2026 UX/UI design
- Color-coded menus
- Keyboard navigation
- Help text integration

---

## 8. Progress Tracking

### 8.1 `lib/progress/panel.sh` (155 lines)

**Role:** Progress panel display

**Responsibilities:**
- Status panel management
- Phase progress tracking
- ANSI code-based panel updates

**Coupling:**
- **Medium Coupling:** Coordinates with estimates and parallel execution
- **Upstream Dependencies:** `estimates.sh`

**Key Functions:**
- `show_progress()` - Progress display
- `start_status_panel()` - Panel startup
- `stop_status_panel()` - Panel cleanup
- `update_status_panel()` - Panel update

**Dependencies:** `estimates.sh`

---

### 8.2 `lib/progress/estimates.sh` (250 lines)

**Role:** Phase timing estimation with adaptive learning

**Responsibilities:**
- Exponential Moving Average (EMA) timing estimates
- Host scaling factors (CPU/RAM/network)
- Phase duration tracking
- Adaptive timing improvements

**Coupling:**
- **Low Coupling:** Read-only timing data
- **Upstream Dependencies:** `profiling.sh`

**Key Functions:**
- `estimate_phase_duration()` - Phase time estimation
- `calculate_ema()` - EMA calculation
- `get_host_scaling_factor()` - Host profile scaling

**Dependencies:** `profiling.sh`

**Algorithm:**
- EMA formula: `new_ema = (alpha * current) + ((1 - alpha) * old_ema)`
- Alpha = 0.2 (20% weight to new data, 80% to historical)
- Host scaling: Faster on better hardware

---

### 8.3 `lib/progress/profiling.sh` (38 lines)

**Role:** Host profiling for scaling factors

**Responsibilities:**
- CPU core detection
- RAM size detection
- Network latency measurement
- Scaling factor calculation

**Coupling:**
- **Low Coupling:** Read-only system queries
- **No Dependencies:** Self-contained

**Key Functions:**
- `profile_host()` - Main profiling function
- `get_cpu_cores()` - CPU detection
- `get_ram_size()` - RAM detection
- `measure_network_latency()` - Network latency

**Dependencies:** None

---

### 8.4 `lib/progress/parallel.sh` (118 lines)

**Role:** DAG-based parallel execution engine

**Responsibilities:**
- Phase dependency graph management
- Parallel phase execution
- Dependency resolution
- Error aggregation

**Coupling:**
- **High Coupling:** Coordinates all maintenance phases
- **Upstream Dependencies:** All maintenance modules

**Key Functions:**
- `execute_parallel()` - Parallel execution entry point
- `build_dag()` - Build dependency graph
- `resolve_dependencies()` - Dependency resolution
- `aggregate_errors()` - Error collection

**Dependencies:** All maintenance modules

**DAG Structure:**
```
clean_tmp → fix_broken_if_any → validate_repos → apt_maintenance
                                    ↓
                           detect_missing_pubkeys → fix_missing_pubkeys
                                                                    ↓
                                                          kernel_purge_phase
```

---

## 9. Package Management

### 9.1 `lib/package_manager.sh` (451 lines)

**Role:** Package manager abstraction layer

**Responsibilities:**
- Package manager detection
- Package manager-specific operations
- Package manager state management
- Cross-package-manager compatibility

**Coupling:**
- **High Coupling:** Interfaces with all platform-specific modules
- **Upstream Dependencies:** `detection.sh`, `platform_utils.sh`

**Key Functions:**
- `pkg_detect()` - Package manager detection
- `pkg_update()` - Package update (NAME COLLISION with packages.sh)
- `pkg_upgrade()` - Package upgrade (NAME COLLISION with packages.sh)
- `pkg_list()` - List installed packages
- `pkg_search()` - Search packages

**Dependencies:** `detection.sh`, `platform_utils.sh`

**Issues Identified:**
- **Name Collision:** `pkg_update()` and `pkg_upgrade()` also exist in `lib/maintenance/packages.sh`
- Potential confusion about which version to call
- Recommend renaming to avoid ambiguity

---

### 9.2 `lib/platform_utils.sh` (198 lines)

**Role:** Platform-aware utility functions

**Responsibilities:**
- Platform-specific utility operations
- Cross-platform compatibility shims
- Platform-specific command wrappers

**Coupling:**
- **Medium Coupling:** Bridges platform layer with maintenance layer
- **Upstream Dependencies:** `detector.sh`

**Key Functions:**
- `platform_aware_exec()` - Platform-aware command execution
- `get_platform()` - Get current platform
- `platform_wrapper()` - Platform-specific wrapper

**Dependencies:** `detector.sh`

---

## 10. Test Infrastructure

### 10.1 Test Suites (32 files)

**Role:** Comprehensive functional testing

**Responsibilities:**
- Smoke testing (60 tests)
- Platform-specific testing (5 OS families)
- Feature testing (security, performance, edge cases)
- Integration testing
- Regression testing

**Coupling:**
- **High Coupling:** Tests main script and library modules
- **Dependencies:** All system components

**Key Suites:**
- `test_suite_smoke.sh` - 60 basic smoke tests
- `test_suite_security.sh` - Security validation tests
- `test_suite_performance.sh` - Performance benchmarks
- `test_suite_debian_family.sh` - Debian family tests
- `test_suite_redhat_family.sh` - RedHat family tests
- `test_suite_arch_family.sh` - Arch family tests
- `test_suite_suse_family.sh` - SUSE family tests
- `test_suite_github_actions.sh` - CI/CD integration tests

**Test Framework:**
- Bash-based testing framework
- PASSED/FAILED counters
- Color-coded output (✅ PASS / ❌ FAIL)
- Exit code 0 for all pass, 1 for any failure

---

### 10.2 Test Runners (8 files)

**Role:** Test orchestration and execution

**Responsibilities:**
- Master test orchestration (`run_all_tests.sh`)
- Profile-based execution (smoke, standard, full)
- OS filtering capability
- Parallel execution support
- Dry-run mode for planning

**Coupling:**
- **High Coupling:** Orchestrates all test suites
- **Dependencies:** All test suites

**Key Runners:**
- `run_all_tests.sh` - Master test orchestrator (294 lines)
- `full_test.sh` - Complete test suite (197 lines)
- `quick_test.sh` - Fast smoke tests
- `run_local_docker_tests.sh` - Docker test orchestration

---

### 10.3 Test Validation (6 files)

**Role:** Test result validation and quality assurance

**Responsibilities:**
- JSON schema validation (`validate_json.py`)
- PR validation (`validate_pr.sh`)
- Test result collection (`collect_test_results.sh`)
- Performance regression detection
- Result comparison (Docker vs GitHub Actions)

**Coupling:**
- **Medium Coupling:** Validates test outputs
- **Dependencies:** Test suites, test runners

**Key Validators:**
- `validate_json.py` - JSON schema validation (28 lines, Python)
- `validate_pr.sh` - PR validation (80+ lines, ShellCheck integration)
- `collect_test_results.sh` - Unified JSON result collector (394 lines)
- `compare_test_results.py` - Python comparison tool (473 lines)

---

## 11. Deployment and Integration

### 11.1 CI/CD Workflows (4 files)

**Role:** Continuous integration and deployment

**Responsibilities:**
- ShellCheck linting
- Test suite execution
- Multi-arch Docker builds (amd64/arm64)
- Automated releases
- Multi-OS test matrix (13 variants)

**Coupling:**
- **High Coupling:** Orchestrates entire project
- **Dependencies:** All system components

**Key Workflows:**
- `.github/workflows/ci.yml` - CI workflow (85 lines)
- `.github/workflows/docker.yml` - Docker build workflow (267 lines)
- `.github/workflows/release.yml` - Release workflow (24 lines)
- `.github/workflows/test-matrix.yml` - Test matrix workflow (433 lines)

---

### 11.2 Docker Configuration (4 files)

**Role:** Container deployment

**Responsibilities:**
- Multi-distribution images (Ubuntu, Debian, Fedora)
- OCI-compliant labels
- Health checks
- Multi-architecture support (amd64/arm64)

**Coupling:**
- **Low Coupling:** Self-contained containers
- **Dependencies:** Main script, libraries

**Key Files:**
- `docker/Dockerfile.default` - Multi-distribution template (107 lines)
- `docker/Dockerfile.ubuntu` - Ubuntu-specific (91 lines)
- `docker/Dockerfile.debian` - Debian-specific (91 lines)
- `docker/Dockerfile.fedora` - Fedora-specific (87 lines)

---

### 11.3 Kubernetes Manifests (6 files)

**Role:** Kubernetes deployment

**Responsibilities:**
- Namespace configuration
- ConfigMap configuration
- RBAC configuration
- Deployment (for debugging)
- DaemonSet (cluster-wide)
- CronJob (scheduled maintenance)

**Coupling:**
- **Low Coupling:** Kubernetes-specific deployment
- **Dependencies:** Docker image

**Key Files:**
- `k8s/namespace.yaml` - Namespace definition (16 lines)
- `k8s/configmap.yaml` - ConfigMap (34 lines)
- `k8s/rbac.yaml` - RBAC rules (89 lines)
- `k8s/deployment.yaml` - Deployment (71 lines)
- `k8s/daemonset.yaml` - DaemonSet (75 lines)
- `k8s/cronjob.yaml` - 3 CronJobs (189 lines)

---

### 11.4 Helm Chart (12 files)

**Role:** Helm package management

**Responsibilities:**
- Chart metadata
- Default configuration values
- Template helpers
- Kubernetes resource templates

**Coupling:**
- **Low Coupling:** Helm-specific packaging
- **Dependencies:** Kubernetes manifests

**Key Files:**
- `helm/sysmaint/Chart.yaml` - Chart metadata (48 lines)
- `helm/sysmaint/values.yaml` - Default values (146 lines)
- `helm/sysmaint/templates/_helpers.tpl` - Template helpers (76 lines)
- `helm/sysmaint/templates/*.yaml` - 8 template files

---

### 11.5 Packaging (4 files)

**Role:** Native package creation

**Responsibilities:**
- Debian package configuration
- RPM spec file
- Systemd units
- Shell completions

**Coupling:**
- **Low Coupling:** Platform-specific packaging
- **Dependencies:** Main script, libraries

**Key Files:**
- `debian/control` - Debian package metadata (27 lines)
- `debian/changelog` - Package changelog (10 lines)
- `debian/rules` - Build rules (13 lines)
- `packaging/sysmaint.spec` - RPM spec file (121 lines)

---

## 12. Documentation

### 12.1 Core Documentation (17 files)

**Role:** Project documentation

**Responsibilities:**
- Project overview and architecture
- Installation and troubleshooting
- Security and governance
- Roadmap and requirements

**Coupling:**
- **No Coupling:** Standalone documentation
- **Dependencies:** None

**Key Files:**
- `README.md` - Main README (16KB)
- `ARCHITECTURE.md` - System architecture
- `PROJECT_STRUCTURE.md` - Project structure
- `INSTALLATION.md` - Installation guide
- `TROUBLESHOOTING.md` - Troubleshooting guide
- `SECURITY.md` - Security policy
- `ROADMAP.md` - Project roadmap
- `PRD.md` - Product requirements

---

### 12.2 Test Documentation (7 files)

**Role:** Test documentation

**Responsibilities:**
- Test architecture documentation
- Test guides and quickstarts
- Test troubleshooting

**Coupling:**
- **No Coupling:** Standalone documentation
- **Dependencies:** None

**Key Files:**
- `TEST_ARCHITECTURE.md` - Test architecture overview
- `TEST_GUIDE.md` - Testing guide
- `TEST_QUICKSTART.md` - Quick start
- `TEST_CHEATSHEET.md` - Testing cheatsheet
- `TEST_MATRIX.md` - Compatibility matrix

---

### 12.3 Deployment Documentation (3 files)

**Role:** Deployment guides

**Responsibilities:**
- Docker deployment guide
- Kubernetes deployment guide
- OS support matrix

**Coupling:**
- **No Coupling:** Standalone documentation
- **Dependencies:** None

**Key Files:**
- `DOCKER.md` - Docker deployment
- `KUBERNETES.md` - Kubernetes deployment
- `OS_SUPPORT.md` - OS support matrix

---

## 13. Cross-Cutting Concerns

### 13.1 Root-Level Libraries (lib/*.sh)

#### `lib/utils.sh` (518 lines)

**Role:** General utility functions

**Responsibilities:**
- Utility functions for logging, progress, validation
- Common operations used across all modules
- Helper functions for system operations

**Coupling:**
- **High Coupling:** Used by most modules
- **No Dependencies:** Self-contained utilities

**Key Functions:**
- Utility wrappers for common operations
- System query helpers
- Validation helpers

**Dependencies:** None

---

#### `lib/subcommands.sh` (287 lines)

**Role:** Embedded subcommands

**Responsibilities:**
- Scanner subcommand
- Profiles subcommand
- Subcommand dispatch and routing

**Coupling:**
- **Medium Coupling:** Called from main script
- **No Dependencies:** Self-contained

**Key Functions:**
- `scanners_main()` - Scanner subcommand
- `profiles_main()` - Profiles subcommand
- `dispatch_subcommand()` - Subcommand routing

**Dependencies:** None

---

### 13.2 Configuration Management

**Configuration Sources (Priority Order):**
1. Environment variables (highest priority)
2. Command-line flags
3. Default values in code

**Key Configuration Variables:**
- `RUN_ID` - Unique run identifier
- `LOG_FILE` - Log file path
- `AUTO_REBOOT` - Auto-reboot if kernel updated
- `DRY_RUN` - Preview mode
- `JSON_SUMMARY` - Emit JSON summary
- `ASSUME_YES` - Auto-confirm prompts
- `PROGRESS_MODE` - Progress display mode
- `NETWORK_RETRY_COUNT` - Network retry attempts
- `LOCK_TIMEOUT` - Lock acquisition timeout

---

### 13.3 State Management

**State Files:**
1. **State File:** `/var/cache/sysmaint/state.json`
   - Phase completion status
   - System metrics
   - Reboot requirement flag

2. **Lock File:** `/var/run/sysmaint.lock`
   - Concurrency control
   - Process ID tracking
   - Timeout management

3. **Log File:** `/var/log/sysmaint/sysmaint_{RUN_ID}.log`
   - Detailed execution log
   - Timestamps for all operations
   - Error messages and warnings

---

### 13.4 Error Handling Strategy

**Error Handling Layers:**
1. **Strict Mode:** `set -Eeuo pipefail`
   - Exit on error
   - Exit on undefined variables
   - Pipe failure detection

2. **Trap Handlers:**
   - `on_exit()` - Always executes
   - `on_err()` - Executes on error
   - Cleanup resources
   - State persistence

3. **Exit Codes:**
   - 0: Success
   - 1: General error
   - 10: Repository validation failures
   - 20: Missing APT public keys
   - 30: Failed systemd services
   - 75: Lock acquisition timeout
   - 100: Reboot required

---

## 14. Duplicated Code Analysis

### 14.1 Exact Duplicates

#### `lib/json.sh` (35 lines) vs `lib/reporting/json.sh` (35 lines)

**Issue:** Exact duplicate of JSON generation utilities

**Impact:**
- Maintenance burden (updates must be made in two places)
- Confusion about which file to use
- Potential for divergence over time

**Recommendation:**
- Remove `lib/json.sh`
- Keep `lib/reporting/json.sh` (better semantic location)
- Update imports in main script

**Action Required:** High

---

### 14.2 Functional Duplicates

#### `pkg_update()` and `pkg_upgrade()` Name Collision

**Files Affected:**
- `lib/package_manager.sh` (lines 180-220)
- `lib/maintenance/packages.sh` (lines 85-150)

**Issue:** Same function names in different modules

**Impact:**
- Confusion about which version to call
- Potential for calling wrong function
- Difficult to trace execution

**Recommendation:**
- Rename functions in `lib/maintenance/packages.sh`:
  - `pkg_update()` → `apt_pkg_update()`
  - `pkg_upgrade()` → `apt_pkg_upgrade()`
- Or create wrapper functions with clear semantics

**Action Required:** Medium

---

### 14.3 Near Duplicates

#### Platform Detection Logic

**Files Affected:**
- `lib/core/detection.sh` (lines 50-300)
- `lib/platform/detector.sh` (lines 30-120)

**Issue:** Similar OS detection logic in two locations

**Impact:**
- Potential for inconsistent detection results
- Maintenance burden

**Recommendation:**
- Consolidate detection logic in `lib/core/detection.sh`
- Make `lib/platform/detector.sh` a thin wrapper

**Action Required:** Low

---

### 14.4 Documentation Duplicates

#### Troubleshooting Documents

**Files Affected:**
- `docs/TROUBLESHOOTING.md`
- `docs/Troubleshooting.md`

**Issue:** Two similar troubleshooting guides

**Impact:**
- User confusion
- Maintenance burden

**Recommendation:**
- Consolidate into single `TROUBLESHOOTING.md`
- Remove `Troubleshooting.md`

**Action Required:** Low

---

## 15. Unused Code Analysis

### 15.1 Potentially Unused Functions

#### `lib/core/capabilities.sh` - Desktop Detection

**Function:** `is_desktop()` (lines 45-65)

**Issue:** Function defined but not extensively used

**Usage:**
- Called in: `lib/maintenance/system.sh` (line 15)
- Only used for thumbnail and browser cache cleanup

**Assessment:** Used but limited scope

**Recommendation:** No action required (function is used)

---

#### `lib/progress/parallel.sh` - DAG Execution

**Function:** `build_dag()` (lines 30-80)

**Issue:** DAG building capability exists but parallel mode is not default

**Usage:**
- Only called when `PARALLEL_EXEC=true`
- Default execution mode is sequential

**Assessment:** Advanced feature, low usage

**Recommendation:** Document as experimental feature

---

### 15.2 Conditional Features

#### Snap Support

**Files:** `lib/maintenance/snap.sh` (172 lines)

**Issue:** Entire module is conditional (only runs if snap installed)

**Usage:**
- Only executed if `snap` command is detected
- Can be disabled via `--no-snap` flag

**Assessment:** Optional feature, not dead code

**Recommendation:** No action required

---

#### Flatpak Support

**Files:** `lib/maintenance/flatpak.sh` (99 lines)

**Issue:** Entire module is conditional (only runs if flatpak installed)

**Usage:**
- Only executed if `flatpak` command is detected
- Can be disabled via `--no-flatpak` flag

**Assessment:** Optional feature, not dead code

**Recommendation:** No action required

---

#### Firmware Support

**Files:** `lib/maintenance/firmware.sh` (53 lines)

**Issue:** Entire module is conditional (only runs if fwupdmgr installed)

**Usage:**
- Only executed if `fwupdmgr` command is detected

**Assessment:** Optional feature, not dead code

**Recommendation:** No action required

---

### 15.3 Test Infrastructure

#### Test Templates

**Directory:** `tests/templates/` (4 files)

**Files:**
- `basic_suite.sh`
- `feature_suite.sh`
- `os_family_suite.sh`
- `README.md`

**Issue:** Templates provided but not actively used

**Usage:**
- Reference for creating new test suites
- Not part of automated test execution

**Assessment:** Developer resources, not dead code

**Recommendation:** No action required (useful for onboarding)

---

## 16. Coupling Analysis

### 16.1 High Coupling Components

#### Main Script (`sysmaint`)

**Coupling Score:** High

**Reason:**
- Loads all 39 library modules
- Orchestrates all 24 execution phases
- Manages all state and configuration

**Impact:**
- Changes to any module may require main script updates
- Difficult to test in isolation
- Large surface area for bugs

**Mitigation:**
- Well-defined module interfaces
- Strict loading order
- Environment variable contracts

**Recommendation:** Consider splitting into smaller orchestrator modules

---

#### `lib/maintenance/packages.sh`

**Coupling Score:** High

**Reason:**
- Interfaces with platform abstraction layer
- Interfaces with package manager abstraction
- Used by main script and other maintenance modules

**Impact:**
- Changes to package manager interface require updates
- Platform-specific logic spread across multiple layers

**Mitigation:**
- Clear abstraction boundaries
- Platform-specific operations isolated

---

#### `lib/reporting/summary.sh`

**Coupling Score:** High

**Reason:**
- Aggregates data from all maintenance and validation modules
- Depends on all phase completion states

**Impact:**
- Changes to any phase may require summary updates
- Complex data flow

**Mitigation:**
- Well-defined data structures
- JSON state file for loose coupling

---

### 16.2 Medium Coupling Components

#### Platform Abstraction Layer

**Coupling Score:** Medium

**Reason:**
- Base platform provides defaults
- Platform-specific modules extend base
- Dynamic module loading

**Impact:**
- Changes to base platform affect all platforms
- Platform-specific quirks require careful handling

**Mitigation:**
- Clear override mechanism
- Platform-specific isolation

---

#### Progress Tracking

**Coupling Score:** Medium

**Reason:**
- Estimates depend on profiling
- Panel depends on estimates
- Parallel execution depends on all maintenance modules

**Impact:**
- Changes to maintenance phases affect DAG
- Timing estimates require historical data

**Mitigation:**
- Adaptive algorithms (EMA)
- Graceful degradation

---

### 16.3 Low Coupling Components

#### Validation Modules

**Coupling Score:** Low

**Reason:**
- Read-only operations
- No side effects
- Clear interfaces

**Impact:**
- Easy to test in isolation
- Minimal dependency risk

**Mitigation:** Not needed (well-designed)

---

#### Core Infrastructure

**Coupling Score:** Low

**Reason:**
- Foundation layer with no dependencies
- Self-contained utilities
- Clear responsibilities

**Impact:**
- Stable foundation for other modules
- Easy to test and maintain

**Mitigation:** Not needed (well-designed)

---

### 16.4 Dependency Graph

```
Main Script (sysmaint)
    ├─ Core Infrastructure (Foundation)
    │   ├─ init.sh (no dependencies)
    │   ├─ detection.sh (depends on: init.sh)
    │   ├─ logging.sh (no dependencies)
    │   ├─ capabilities.sh (no dependencies)
    │   └─ error_handling.sh (depends on: logging.sh, init.sh)
    │
    ├─ Progress Tracking
    │   ├─ profiling.sh (no dependencies)
    │   ├─ estimates.sh (depends on: profiling.sh)
    │   ├─ panel.sh (depends on: estimates.sh)
    │   └─ parallel.sh (depends on: all maintenance modules)
    │
    ├─ Platform Abstraction
    │   ├─ detector.sh (depends on: init.sh, detection.sh)
    │   ├─ base.sh (no dependencies)
    │   ├─ debian.sh (depends on: base.sh)
    │   ├─ redhat.sh (depends on: base.sh)
    │   ├─ arch.sh (depends on: base.sh)
    │   └─ suse.sh (depends on: base.sh)
    │
    ├─ OS Families
    │   ├─ debian_family.sh (no dependencies)
    │   ├─ redhat_family.sh (no dependencies)
    │   ├─ arch_family.sh (no dependencies)
    │   └─ suse_family.sh (no dependencies)
    │
    ├─ Maintenance Operations
    │   ├─ packages.sh (depends on: platform_utils.sh, package_manager.sh)
    │   ├─ kernel.sh (depends on: platform_utils.sh, package_manager.sh)
    │   ├─ snap.sh (depends on: capabilities.sh)
    │   ├─ flatpak.sh (depends on: capabilities.sh)
    │   ├─ firmware.sh (depends on: capabilities.sh)
    │   ├─ system.sh (depends on: capabilities.sh)
    │   └─ storage.sh (depends on: capabilities.sh)
    │
    ├─ Validation
    │   ├─ repos.sh (depends on: platform_utils.sh, package_manager.sh)
    │   ├─ keys.sh (depends on: platform_utils.sh, package_manager.sh)
    │   ├─ services.sh (no dependencies)
    │   └─ security.sh (no dependencies)
    │
    ├─ Reporting
    │   ├─ json.sh (no dependencies)
    │   ├─ reboot.sh (no dependencies)
    │   └─ summary.sh (depends on: all maintenance and validation modules)
    │
    └─ User Interface
        └─ interface.sh (no dependencies, requires: dialog/whiptail)
```

---

## 17. Component Quality Assessment

### 17.1 Well-Designed Components

#### Core Infrastructure
- **Strength:** Clear separation of concerns
- **Strength:** Low coupling
- **Strength:** Foundation layer with no dependencies
- **Assessment:** Excellent design

---

#### Validation Modules
- **Strength:** Read-only operations
- **Strength:** Clear interfaces
- **Strength:** Easy to test
- **Assessment:** Excellent design

---

#### Platform Abstraction
- **Strength:** Consistent interface across platforms
- **Strength:** Platform-specific isolation
- **Strength:** Dynamic loading
- **Assessment:** Good design

---

### 17.2 Components Needing Attention

#### Main Script
- **Issue:** 5,008 lines in single file
- **Issue:** High coupling to all modules
- **Issue:** Complex orchestration logic
- **Recommendation:** Consider splitting into multiple orchestrator modules

---

#### Package Management
- **Issue:** Name collision (`pkg_update()`, `pkg_upgrade()`)
- **Issue:** Abstraction layers may be confusing
- **Recommendation:** Rename functions for clarity

---

#### Reporting Summary
- **Issue:** High coupling to all modules
- **Issue:** 354 lines of aggregation logic
- **Recommendation:** Consider breaking into smaller summary modules

---

### 17.3 Technical Debt Summary

| Category | Severity | Count | Effort to Fix |
|----------|----------|-------|---------------|
| Exact Duplicates | High | 1 | Low (1 hour) |
| Name Collisions | Medium | 1 | Low (2 hours) |
| Large Files | Medium | 3 | High (1-2 days each) |
| Documentation Dupes | Low | 1 | Low (1 hour) |
| Near Duplicates | Low | 2 | Medium (4-8 hours) |

**Total Technical Debt:** 8 items
**High Priority:** 1 item (exact duplicate)
**Medium Priority:** 2 items (name collision, large files)
**Low Priority:** 5 items (documentation, near duplicates)

---

## 18. Recommendations

### 18.1 Immediate Actions (High Priority)

1. **Remove Exact Duplicate:**
   - Remove `lib/json.sh`
   - Update imports in main script
   - **Effort:** 1 hour
   - **Impact:** Eliminates maintenance burden

---

### 18.2 Short-Term Actions (Medium Priority)

1. **Fix Name Collision:**
   - Rename functions in `lib/maintenance/packages.sh`
   - Update all call sites
   - **Effort:** 2 hours
   - **Impact:** Eliminates confusion

2. **Consolidate Documentation:**
   - Merge `TROUBLESHOOTING.md` and `Troubleshooting.md`
   - Remove duplicate
   - **Effort:** 1 hour
   - **Impact:** Improved user experience

---

### 18.3 Long-Term Actions (Low Priority)

1. **Refactor Main Script:**
   - Split 5,008-line script into smaller modules
   - Create `lib/orchestration/` directory
   - Extract phase orchestration logic
   - **Effort:** 2-3 days
   - **Impact:** Improved maintainability

2. **Consolidate Platform Detection:**
   - Merge duplicate detection logic
   - Single source of truth for OS detection
   - **Effort:** 4-6 hours
   - **Impact:** Reduced confusion

3. **Split Summary Module:**
   - Break 354-line summary into smaller modules
   - Create `lib/reporting/metrics.sh`, `lib/reporting/recommendations.sh`
   - **Effort:** 1 day
   - **Impact:** Improved testability

---

## Appendix A: Component Metrics

### File Size Distribution

| Size Range | Count | Percentage |
|------------|-------|------------|
| < 50 lines | 8 | 12% |
| 50-100 lines | 15 | 23% |
| 100-200 lines | 22 | 33% |
| 200-500 lines | 14 | 21% |
| 500-1000 lines | 5 | 8% |
| > 1000 lines | 2 | 3% |

**Largest Files:**
1. `sysmaint` - 5,008 lines
2. `lib/gui/interface.sh` - 786 lines
3. `lib/maintenance/packages.sh` - 357 lines
4. `lib/reporting/summary.sh` - 354 lines
5. `lib/os_families/arch_family.sh` - 392 lines

---

### Coupling Score Distribution

| Coupling Level | Count | Percentage |
|----------------|-------|------------|
| Low | 28 | 42% |
| Medium | 25 | 38% |
| High | 13 | 20% |

**Highest Coupling:**
1. `sysmaint` - High (orchestrates all modules)
2. `lib/maintenance/packages.sh` - High (bridges layers)
3. `lib/reporting/summary.sh` - High (aggregates all data)
4. `lib/progress/parallel.sh` - High (coordinates phases)

---

### Dependency Depth

| Depth | Count | Percentage |
|-------|-------|------------|
| 0 (no dependencies) | 24 | 36% |
| 1 (one level) | 28 | 42% |
| 2 (two levels) | 10 | 15% |
| 3+ (deep) | 4 | 6% |

**Deepest Dependencies:**
1. `lib/reporting/summary.sh` - Depth 3 (all modules → data → summary)
2. `lib/progress/parallel.sh` - Depth 3 (all modules → DAG → parallel)
3. `lib/maintenance/packages.sh` - Depth 2 (platform → abstraction → packages)

---

## Appendix B: Component Reference Matrix

### Main Script → Library Dependencies

```
sysmaint depends on:
├── lib/core/init.sh ✓
├── lib/core/detection.sh ✓
├── lib/core/logging.sh ✓
├── lib/core/capabilities.sh ✓
├── lib/core/error_handling.sh ✓
├── lib/progress/panel.sh ✓
├── lib/progress/estimates.sh ✓
├── lib/progress/profiling.sh ✓
├── lib/progress/parallel.sh ✓
├── lib/maintenance/packages.sh ✓
├── lib/maintenance/kernel.sh ✓
├── lib/maintenance/snap.sh ✓
├── lib/maintenance/flatpak.sh ✓
├── lib/maintenance/firmware.sh ✓
├── lib/maintenance/system.sh ✓
├── lib/maintenance/storage.sh ✓
├── lib/validation/repos.sh ✓
├── lib/validation/keys.sh ✓
├── lib/validation/services.sh ✓
├── lib/validation/security.sh ✓
├── lib/reporting/json.sh ✓
├── lib/reporting/summary.sh ✓
├── lib/reporting/reboot.sh ✓
└── lib/gui/interface.sh ✓
```

---

### Platform Module → OS Family Dependencies

```
lib/platform/debian.sh → lib/os_families/debian_family.sh (implicit)
lib/platform/redhat.sh → lib/os_families/redhat_family.sh (implicit)
lib/platform/arch.sh → lib/os_families/arch_family.sh (implicit)
lib/platform/suse.sh → lib/os_families/suse_family.sh (implicit)
```

---

**Document Version:** 1.0.0
**Last Updated:** 2026-01-15
**Analysis Scope:** All 215 project files
**Total Components Analyzed:** 66 main components
**Total Lines of Code Analyzed:** ~24,000+

---

## Summary

This component analysis document provides a comprehensive catalog of all SYSMAINT project components, including:

- **66 main components** catalogued with roles and responsibilities
- **1 exact duplicate identified** (`lib/json.sh`)
- **1 name collision identified** (`pkg_update()`/`pkg_upgrade()`)
- **3 large files flagged** for potential refactoring (>500 lines)
- **13 high-coupling components** identified
- **28 low-coupling components** (well-designed)
- **8 technical debt items** categorized by priority

**Key Findings:**
1. Overall architecture is well-designed with clear separation of concerns
2. Platform abstraction layer is excellent (supports 4 OS families, 9 distributions)
3. Test infrastructure is comprehensive (32 test suites, professional-grade)
4. One exact duplicate requires immediate removal
5. One name collision requires renaming for clarity
6. Main script is large but manageable (5,008 lines with clear sections)

**Recommendations:**
- Remove `lib/json.sh` duplicate (1 hour effort)
- Fix `pkg_update()`/`pkg_upgrade()` name collision (2 hours effort)
- Consider refactoring main script into smaller modules (2-3 days effort)
- Consolidate troubleshooting documentation (1 hour effort)
