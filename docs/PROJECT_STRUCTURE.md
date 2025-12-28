# SYSMAINT — Project Structure

**Directory Organization & File Layout**

---

## Overview

This document describes the complete directory structure of the SYSMAINT project, providing a clear reference for contributors, stakeholders, and users.

---

## Root Directory Structure

```
sysmaint/
├── README.md                    # Main project landing page
├── LICENSE                      # MIT License
├── sysmaint                     # Main executable script (5,008 lines)
│
├── docs/                        # All documentation (centralized)
├── lib/                         # Library modules
├── tests/                       # Test suite
├── scripts/                     # Utility scripts
├── packaging/                   # Packaging configurations
│
├── debian/                      # Debian package build files
├── .github/                     # GitHub workflows & templates
├── .docker/                     # Docker build context
│
├── Dockerfile                   # Container image build
├── .dockerignore                # Docker exclusion patterns
├── .gitignore                   # Git exclusion patterns
└── .vscode/                     # VS Code settings
```

---

## Directory Details

### `/docs/` — Documentation (All Centralized)

```
docs/
├── PRD.md                       # Product Requirements Document ⭐
├── VISION.md                    # Phase 1: Vision and Ideation
├── REQUIREMENTS.md              # Phase 2: Enterprise Requirements
├── ARCHITECTURE.md              # Phase 3: System Architecture
├── INSTALLATION.md              # Installation guide
├── TROUBLESHOOTING.md           # Common issues & solutions
├── PERFORMANCE.md               # Benchmarks and optimization
├── SECURITY.md                  # Security policy & best practices
├── FAQ.md                       # Frequently Asked Questions
├── ROADMAP.md                   # Version planning
├── GOVERNANCE.md                # Development guidelines
│
├── CODE_OF_CONDUCT.md           # Community guidelines
├── CONTRIBUTING.md              # Contribution guidelines
│
├── Development-Guide.md         # Developer documentation
├── Installation-Guide.md        # Detailed installation
├── Troubleshooting.md           # Additional troubleshooting
├── Home.md                      # Wiki home page
│
├── man/                         # Manual pages
│   ├── sysmaint.1               # Main man page
│   └── sysmaint.conf.5          # Config man page
│
├── schema/                      # JSON schemas
│   └── output-schema.json       # JSON output validation
│
└── social-preview.svg           # Social media preview image
```

### `/lib/` — Library Modules

```
lib/
├── core/                        # Core functionality
│   ├── init.sh                  # Initialization & OS detection
│   ├── capabilities.sh          # Capability checks
│   └── lock.sh                  # File locking mechanism
│
├── maintenance/                 # Maintenance operations
│   ├── packages.sh              # Package management abstraction
│   ├── cleanup.sh               # System cleanup operations
│   └── kernels.sh               # Kernel management
│
├── security/                    # Security operations
│   ├── audit.sh                 # Security auditing
│   └── validation.sh            # Security validation
│
├── reporting/                   # Output & reporting
│   ├── json.sh                  # JSON output generation
│   ├── summary.sh               # Summary reporting
│   └── logging.sh               # Logging utilities
│
└── ui/                          # User interfaces
    ├── cli.sh                   # CLI interface
    ├── tui.sh                   # Terminal UI (dialog)
    └── colors.sh                # Terminal colors
```

### `/tests/` — Test Suite

```
tests/
├── test_suite_smoke.sh          # Smoke tests
├── test_suite_security.sh       # Security tests
├── test_suite_performance.sh    # Performance benchmarks
├── test_suite_*.sh              # Additional test suites
│
├── validate_json.py             # JSON schema validation
├── mock/                        # Mock binaries for testing
│   ├── apt
│   ├── dnf
│   └── pacman
│
└── fixtures/                    # Test fixtures & data
```

### `/scripts/` — Utility Scripts

```
scripts/
├── build.sh                     # Build automation
├── test.sh                      # Test runner
├── release.sh                   # Release automation
└── install.sh                   # Installation script
```

### `/packaging/` — Packaging Configurations

```
packaging/
├── systemd/                     # Systemd service files
│   ├── sysmaint.service
│   └── sysmaint.timer
│
├── rpm/                         # RPM packaging
│   └── sysmaint.spec
│
└── completion/                  # Shell completion scripts
    ├── bash
    │   └── sysmaint
    └── zsh
        └── _sysmaint
```

### `/debian/` — Debian Packaging

```
debian/
├── changelog                    # Package changelog
├── control                      # Package control file
├── rules                        # Build rules
└── compat                       # Debhelper compatibility
```

### `/.github/` — GitHub Configuration

```
.github/
├── workflows/                   # CI/CD workflows
│   ├── test.yml                 # Testing workflow
│   ├── security.yml             # Security scanning
│   └── release.yml              # Release automation
│
├── ISSUE_TEMPLATE/              # Issue templates
├── PULL_REQUEST_TEMPLATE.md     # PR template
└── dependabot.yml               # Dependency updates
```

### `/.docker/` — Docker Build Context

```
.docker/
├── entrypoint.sh                # Container entrypoint
└── healthcheck.sh               # Health check script
```

---

## File Organization Philosophy

### Centralization Principle

All documentation, markdown files, and writing are centralized under `/docs/` to:
- Reduce root directory clutter
- Provide single source of truth
- Simplify navigation for stakeholders
- Enable better documentation maintenance

### Separation of Concerns

| Directory | Purpose | Owner |
|-----------|---------|-------|
| `/docs/` | All documentation | Technical Writer |
| `/lib/` | Core library code | Developers |
| `/tests/` | Test automation | QA Engineers |
| `/packaging/` | Distribution packaging | Release Manager |
| `/.github/` | GitHub integration | DevOps |
| `/scripts/` | Build/utility scripts | Developers |

---

## Quick Reference

### Key Files

| File | Purpose | Link |
|------|---------|------|
| `README.md` | Project landing page | [View](../README.md) |
| `docs/PRD.md` | Product Requirements | [View](PRD.md) |
| `docs/ARCHITECTURE.md` | System design | [View](ARCHITECTURE.md) |
| `docs/INSTALLATION.md` | Setup guide | [View](INSTALLATION.md) |
| `sysmaint` | Main executable | [View](../sysmaint) |

### Documentation Navigation

```
Start → README.md → docs/PRD.md → Other docs as needed
         ↓
    docs/INSTALLATION.md (for setup)
    docs/ARCHITECTURE.md (for developers)
    docs/TROUBLESHOOTING.md (for issues)
```

---

## Stakeholder Quick Links

| Role | Key Documents |
|------|---------------|
| **Product Manager** | PRD.md, VISION.md, ROADMAP.md |
| **Developer** | ARCHITECTURE.md, CONTRIBUTING.md, lib/ |
| **QA Engineer** | REQUIREMENTS.md, tests/ |
| **Security Analyst** | SECURITY.md, lib/security/ |
| **End User** | README.md, INSTALLATION.md, TROUBLESHOOTING.md |
| **Release Manager** | ROADMAP.md, packaging/ |

---

**Document Version:** 1.0.0
**Last Updated:** 2025-12-28
