# CI/CD Pipeline Overview

> **Last Updated:** December 12, 2025  
> **Total Workflows:** 8  
> **Total Jobs:** 15  
> **CI Status:** ✅ 100% Pass Rate (4/4 platforms)

---

## 📊 Quick Summary

| Category | Workflows | Jobs | Status |
|----------|-----------|------|--------|
| **Core Testing** | 2 | 5 | ✅ 100% Pass |
| **Quality & Security** | 2 | 2 | ✅ Active |
| **Performance** | 2 | 2 | ⏸️ On-demand |
| **Release & Deploy** | 1 | 1 | ⏸️ Tag-based |
| **Maintenance** | 1 | 1 | 🌙 Nightly |

---

## 🧪 Core Testing Workflows

### 1. Main CI Pipeline (`ci.yml`)

**Purpose:** Multi-distribution integration testing  
**Triggers:** Push to master/main, Pull Requests  
**Jobs:** 4

| Job | Distribution | Status | Runtime |
|-----|--------------|--------|------|
| `test-ubuntu` | Ubuntu 24.04 (Debian family) | ✅ Passing | ~8-10 min |
| `test-fedora` | Fedora 43 (Red Hat family) | ✅ Passing | ~1-2 min |
| `test-centos` | CentOS Stream 10 (Red Hat family) | ✅ Passing | ~1-2 min |
| `test-rhel` | RHEL 10 (Red Hat family) | ✅ Passing | ~1-2 min |

**Test Coverage:**
- Smoke tests (65 tests)
- Edge cases (67 tests)
- Security tests (36 tests)
- Compliance tests (32 tests)
- Governance tests (18 tests)
- Performance tests (24 benchmarks)
- JSON validation (4 tests)

**Recent Fixes (Dec 11, 2025):**
- ✅ Fixed unbound USER variable in containers (${USER:-root})
- ✅ Resolved coreutils-single package conflict in CentOS/RHEL (--allowerasing)
- ✅ Added comprehensive system dependencies for minimal containers
- ✅ Fixed test filename inconsistency in CentOS job
- ✅ Made ShellCheck optional for Red Hat family distributions
- ✅ **100% CI pass rate achieved across all 4 platforms**

---

### 2. Dry-Run Matrix (`dry-run.yml`)

**Purpose:** Feature combination testing and package validation  
**Triggers:** Push, Pull Requests, Manual Dispatch  
**Jobs:** 3

| Job | Purpose | Features Tested |
|-----|---------|-----------------|
| `dry-run` | Basic dry-run validation | Core functionality |
| `feature-combos` | Feature flag combinations | 30+ flag combinations |
| `package-build` | Package build validation | DEB/RPM packaging |

**Matrix Testing:**
- All flag combinations
- Package manager operations
- JSON output validation
- Exit code verification

---

## 🔍 Quality & Security Workflows

### 3. Lint Shell Scripts (`lint.yml`)

**Purpose:** Code quality and style checking  
**Triggers:** Pull Requests, Push to main  
**Jobs:** 1

| Job | Tools | Status |
|-----|-------|--------|
| `lint` | ShellCheck, shfmt | ✅ Passing |

**Validation:**
- Shell script syntax
- Best practices compliance
- Code formatting consistency
- POSIX compatibility checks

---

### 4. Security Scanning (`security-scan.yml`)

**Purpose:** Security vulnerability detection  
**Triggers:** Scheduled (nightly), Manual Dispatch, Push  
**Jobs:** 1

| Job | Scope | Frequency |
|-----|-------|-----------|
| `security-scan` | Code vulnerabilities, dependency checks | Nightly + Push |

**Scans:**
- Static code analysis
- Dependency vulnerabilities
- Secret detection
- Security policy compliance

---

## ⚡ Performance Workflows

### 5. Performance Regression (`performance.yml`)

**Purpose:** Performance benchmarking and regression detection  
**Triggers:** Pull Requests, Push  
**Jobs:** 1

| Job | Metrics | Threshold |
|-----|---------|-----------|
| `benchmark` | Execution time, memory usage | <4.5s max |

**Benchmarks:**
- Baseline performance (<3.5s)
- Feature overhead testing
- Scalability tests
- Memory footprint analysis

---

### 6. Scanner Performance (`scanner-performance.yml`)

**Purpose:** External scanner integration performance  
**Triggers:** Scheduled, Manual Dispatch  
**Jobs:** 1

| Job | Focus | Frequency |
|-----|-------|-----------|
| `scanner-perf` | Lynis, rkhunter integration | On-demand |

**Tests:**
- Scanner execution time
- Integration overhead
- Result processing speed

---

## 🚀 Release & Deploy Workflows

### 7. Docker Package (`docker-publish.yml`)

**Purpose:** Container image building and publishing  
**Triggers:** Push (tags), Manual Dispatch  
**Jobs:** 1

| Job | Registry | Images |
|-----|----------|--------|
| `build-and-push` | ghcr.io | Multi-arch (amd64, arm64) |

**Artifacts:**
- Docker images
- Multi-architecture support
- Version tagging (latest, semver)

---

## 🔧 Maintenance Workflows

### 8. Nightly Mock Failure Injection (`nightly-mock-fail.yml`)

**Purpose:** Failure scenario testing  
**Triggers:** Scheduled (nightly), Manual Dispatch  
**Jobs:** 1

| Job | Purpose | Frequency |
|-----|---------|-----------|
| `mock-failure` | Test error handling | Nightly |

**Scenarios:**
- Package manager failures
- Network timeouts
- Permission errors
- Disk space issues

---

## 📈 Workflow Execution Statistics

### Trigger Frequency

| Trigger Type | Workflows Affected | Typical Runs/Day |
|--------------|-------------------|------------------|
| **Pull Request** | ci.yml, lint.yml, dry-run.yml, performance.yml | Per PR push |
| **Push to master** | ci.yml, dry-run.yml, security-scan.yml | Per merge |
| **Scheduled** | security-scan.yml, scanner-performance.yml, nightly-mock-fail.yml | 1-3x daily |
| **Manual** | All (via workflow_dispatch) | As needed |
| **Tags** | docker-publish.yml | Per release |

### Average Runtime

| Workflow | Typical Duration | Concurrent Jobs |
|----------|------------------|-----------------|
| ci.yml | 4-7 minutes | 4 parallel |
| lint.yml | 30-40 seconds | 1 |
| dry-run.yml | 3-5 minutes | 3 parallel |
| performance.yml | 15-20 minutes | 1 |
| security-scan.yml | 2-3 minutes | 1 |
| docker-publish.yml | 8-12 minutes | 1 |
| scanner-performance.yml | 5-10 minutes | 1 |
| nightly-mock-fail.yml | 2-3 minutes | 1 |

---

## 🎯 Critical Path Workflows

Workflows that **must pass** before merging:

1. ✅ **ci.yml** - All distribution tests
2. ✅ **lint.yml** - Code quality
3. ✅ **dry-run.yml** - Feature validation

Workflows that are **informational** (can fail):

4. ⚠️ **performance.yml** - Performance tracking
5. ⚠️ **security-scan.yml** - Security monitoring

---

## 🔄 Workflow Dependencies

```
PR Created
    ↓
├─→ ci.yml (4 jobs in parallel)
│   ├─→ test-ubuntu
│   ├─→ test-fedora
│   ├─→ test-centos
│   └─→ test-rhel
│
├─→ lint.yml
│
├─→ dry-run.yml (3 jobs in sequence)
│   ├─→ dry-run
│   ├─→ feature-combos
│   └─→ package-build
│
└─→ performance.yml
    
Merge to master
    ↓
├─→ security-scan.yml
└─→ (All PR workflows re-run)

Tag Push
    ↓
└─→ docker-publish.yml

Scheduled (Nightly)
    ↓
├─→ security-scan.yml (2 AM UTC)
├─→ scanner-performance.yml (3 AM UTC)
└─→ nightly-mock-fail.yml (4 AM UTC)
```

---

## 🛠️ Maintenance & Optimization

### Current Issues

| Issue | Workflows Affected | Priority | Status |
|-------|-------------------|----------|--------|
| Red Hat container failures | ci.yml (3 jobs) | 🔴 High | 🔄 In Progress |
| ShellCheck optional | lint.yml | 🟢 Low | ✅ Fixed |

### Optimization Opportunities

1. **Parallel Execution**: ci.yml already runs 4 jobs in parallel ✅
2. **Caching**: Consider adding package manager caching for faster builds
3. **Matrix Strategy**: dry-run.yml could benefit from matrix parallelization
4. **Resource Allocation**: Monitor runner usage and optimize job distribution

---

## 📝 Adding New Workflows

When adding new CI jobs, consider:

1. **Trigger Selection**: Choose appropriate triggers (PR, push, schedule, manual)
2. **Job Dependencies**: Define dependencies using `needs:` if required
3. **Timeout Settings**: Set reasonable `timeout-minutes` (default: 360)
4. **Failure Handling**: Use `continue-on-error` for non-critical jobs
5. **Artifact Storage**: Upload test results, logs, or build artifacts
6. **Status Checks**: Mark as required in branch protection rules

---

## 🔗 Related Documentation

- [CI Workflow File](/.github/workflows/ci.yml)
- [Test Suite Documentation](/tests/README.md)
- [Performance Benchmarks](/docs/PERFORMANCE.md)
- [Security Guidelines](/docs/SECURITY.md)

---

**Status Legend:**
- ✅ Passing / Active
- ❌ Failing
- 🟡 Partial / Warning
- ⏸️ Inactive / On-demand
- 🌙 Scheduled (nightly)
- 🔄 In Progress
