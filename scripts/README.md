# OCTALUM-PULSE Utility Scripts

This directory contains utility scripts for development, packaging, and CI/CD operations.

## 📁 Scripts

### cleanup_workflows.sh
Cleans up old GitHub Actions workflows.

**Usage:**
```bash
bash scripts/cleanup_workflows.sh
```

**Purpose:** Remove deprecated workflow files from `.github/workflows/`

### publish-packages.sh
Publishes built packages to package repositories.

**Usage:**
```bash
bash scripts/publish-packages.sh [OPTIONS]
```

**Purpose:** Upload `.deb` packages to Debian repository.

---

## 🔧 Development Workflow

These scripts are used during:
- Package building
- CI/CD pipeline operations
- Repository maintenance

## 📖 Related Documentation

- [PACKAGING.md](../docs/INSTALLATION.md) - Installation and packaging
- [CONTRIBUTING.md](../docs/CONTRIBUTING.md) - Development workflow

---

**SPDX-License-Identifier:** MIT  
**Copyright (c) 2025 Harery**
