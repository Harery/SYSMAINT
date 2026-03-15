# OCTALUM-PULSE Library Modules

This directory contains core library modules used by the main `pulse` script.

## 📁 Structure

```
lib/
├── core/              # Core functionality modules
├── gui/               # TUI/Dialog-based interface modules  
├── maintenance/       # System maintenance operations
├── os_families/       # OS family-specific logic
├── package_manager.sh # Package management abstraction
├── platform/          # Platform detection and compatibility
├── platform_utils.sh  # Platform utility functions
├── progress/          # Progress indicators and spinners
└── reporting/         # JSON/text reporting modules
```

## 🔧 Modules

### core/
Essential core functionality including:
- Configuration management
- Logging utilities
- Error handling
- State management

### gui/
Terminal User Interface components:
- Dialog-based menus
- Interactive prompts
- Progress displays

### maintenance/
System maintenance operations:
- Package updates
- Cache cleanup
- Log rotation
- Kernel management

### os_families/
OS-specific logic for:
- Debian family (Ubuntu, Debian)
- Red Hat family (RHEL, Fedora, Rocky, Alma)
- Arch Linux
- openSUSE

### package_manager.sh
Unified package management interface supporting:
- apt (Debian/Ubuntu)
- dnf/yum (Red Hat family)
- pacman (Arch)
- zypper (openSUSE)

### platform/ & platform_utils.sh
Platform detection and compatibility:
- OS identification
- Version detection
- Feature availability checks

### progress/
Visual feedback components:
- Spinners
- Progress bars
- Counters

### reporting/
Output formatting:
- JSON generation
- Summary reports
- Telemetry data

## 📖 Usage

Library modules are sourced by the main `pulse` script:

```bash
source lib/package_manager.sh
source lib/platform/detect.sh
```

## 🧪 Testing

Library modules are tested by the test suites in `tests/`:
- `tests/test_suite_functions.sh` - Core function tests
- `tests/test_suite_features.sh` - Feature integration tests

---

**SPDX-License-Identifier:** MIT  
**Copyright (c) 2025 Harery**
