# SYSMAINT Performance Baselines

**Document Version:** 1.0  
**Date:** December 28, 2025  
**Status:** DRAFT - Awaiting Real Test Data  
**SPDX-License-Identifier:** MIT

---

## Overview

This document defines the performance baselines for SYSMAINT across all supported operating systems and test scenarios. Baselines are established through actual test runs and serve as reference points for regression detection.

---

## Performance Thresholds

### Execution Time Thresholds

| Environment | Fast | Acceptable | Slow | Critical |
|-------------|------|------------|------|----------|
| **Local (Modern CPU)** | < 3s | < 10s | < 30s | ≥ 30s |
| **CI/CD (Shared Runner)** | < 5s | < 20s | < 60s | ≥ 60s |
| **Docker (Container)** | < 4s | < 15s | < 45s | ≥ 45s |

### Memory Usage Thresholds

| Metric | Target | Warning | Critical |
|--------|--------|---------|----------|
| **Peak Memory** | < 50 MB | < 75 MB | ≥ 75 MB |
| **Average Memory** | < 30 MB | < 50 MB | ≥ 50 MB |

---

## Baseline Benchmarks by Category

### 1. Baseline Benchmarks

Dry-run mode performance (no actual changes made):

| Test Name | Target (Local) | Target (CI) | Notes |
|-----------|----------------|-------------|-------|
| `baseline-minimal` | 1-2s | 2-4s | Basic dry-run, minimal output |
| `baseline-default` | 1-3s | 2-5s | Default dry-run with JSON summary |
| `baseline-with-upgrade` | 2-4s | 3-7s | Dry-run with package upgrade check |

### 2. Feature-Specific Benchmarks

Individual feature performance in dry-run mode:

| Test Name | Target (Local) | Target (CI) | Notes |
|-----------|----------------|-------------|-------|
| `feature-security-audit` | 2-3s | 3-6s | Security checks only |
| `feature-check-zombies` | 1-2s | 2-4s | Zombie process detection |
| `feature-browser-cache` | 1-2s | 2-4s | Browser cache reporting |
| `feature-kernel-purge` | 1-2s | 2-4s | Old kernel identification |
| `feature-orphan-purge` | 1-2s | 2-4s | Orphaned package detection |

### 3. Combined Load Benchmarks

Multiple features combined:

| Test Name | Target (Local) | Target (CI) | Notes |
|-----------|----------------|-------------|-------|
| `load-moderate` | 3-5s | 5-10s | 3-4 features combined |
| `load-heavy` | 4-7s | 7-15s | 5-6 features combined |
| `load-maximum` | 5-10s | 10-20s | All features enabled |

### 4. Scalability Benchmarks

Performance with varying data sizes:

| Test Name | Target (Local) | Target (CI) | Notes |
|-----------|----------------|-------------|-------|
| `scale-journal-1d` | 1-2s | 2-4s | 1 day of journal logs |
| `scale-journal-30d` | 2-3s | 3-6s | 30 days of journal logs |
| `scale-journal-365d` | 3-5s | 5-10s | 365 days of journal logs |
| `scale-kernel-1` | 1-2s | 2-4s | Keep 1 kernel |
| `scale-kernel-5` | 1-2s | 2-4s | Keep 5 kernels |
| `scale-kernel-10` | 2-3s | 3-6s | Keep 10 kernels |

### 5. Display Mode Benchmarks

Different progress display modes:

| Test Name | Target (Local) | Target (CI) | Notes |
|-----------|----------------|-------------|-------|
| `display-quiet` | 1-2s | 2-4s | Minimal output |
| `display-dots` | 1-2s | 2-4s | Dot progress indicator |
| `display-spinner` | 1-2s | 2-4s | Spinner animation |
| `display-countdown` | 1-2s | 2-4s | Countdown timer |

### 6. JSON Output Benchmarks

JSON telemetry overhead:

| Test Name | Target (Local) | Target (CI) | Notes |
|-----------|----------------|-------------|-------|
| `json-disabled` | 1-2s | 2-4s | No JSON output |
| `json-enabled` | 1-3s | 2-5s | JSON summary enabled |
| `json-full-telemetry` | 3-5s | 5-10s | All features with JSON |

---

## OS-Specific Baselines

Expected performance variations by OS family:

### Debian Family (Ubuntu, Debian)

| Test | Target Range | Notes |
|------|--------------|-------|
| `baseline-default` | 1.5-2.5s | Fastest (apt is efficient) |
| `load-moderate` | 3-5s | Good performance |
| `load-heavy` | 5-8s | Moderate slowdown |

### Red Hat Family (Fedora, RHEL, Rocky, Alma, CentOS)

| Test | Target Range | Notes |
|------|--------------|-------|
| `baseline-default` | 2-3s | Moderate (dnf/yum) |
| `load-moderate` | 4-6s | Consistent |
| `load-heavy` | 6-10s | Slightly slower |

### Arch Linux

| Test | Target Range | Notes |
|------|--------------|-------|
| `baseline-default` | 1.5-2.5s | Fast (pacman is optimized) |
| `load-moderate` | 3-5s | Good performance |
| `load-heavy` | 5-8s | Moderate slowdown |

### openSUSE

| Test | Target Range | Notes |
|------|--------------|-------|
| `baseline-default` | 2-3s | Moderate (zypper) |
| `load-moderate` | 4-6s | Consistent |
| `load-heavy` | 6-10s | Slightly slower |

---

## Regression Detection Criteria

### Time-Based Regression

A regression is flagged when:
- **Minor Regression:** 10-20% slower than baseline
- **Moderate Regression:** 20-50% slower than baseline
- **Severe Regression:** >50% slower than baseline
- **Critical Regression:** Exceeds "Slow" threshold

### Memory-Based Regression

A regression is flagged when:
- **Minor Regression:** 10-25% more memory than baseline
- **Moderate Regression:** 25-50% more memory than baseline
- **Severe Regression:** >50% more memory than baseline
- **Critical Regression:** Exceeds 75 MB peak

---

## Baseline Data Collection

### How to Establish Baselines

1. **Run performance tests on clean system:**
   ```bash
   cd /path/to/sysmaint
   bash tests/test_suite_performance.sh
   ```

2. **Collect results from each OS:**
   ```bash
   # Ubuntu 22.04
   docker run --rm -v $(pwd):/sysmaint ubuntu:22.04 bash /sysmaint/tests/test_suite_performance.sh
   
   # Fedora 41
   docker run --rm -v $(pwd):/sysmaint fedora:41 bash /sysmaint/tests/test_suite_performance.sh
   ```

3. **Update this document with actual measurements:**
   - Replace "Target" ranges with "Actual" values
   - Add OS-specific variations
   - Document any anomalies

### Baseline Template

```markdown
| OS Version | Test | Actual Avg | Min | Max | Median | Memory | Date |
|------------|------|------------|-----|-----|--------|--------|------|
| Ubuntu 22.04 | baseline-default | TBD | TBD | TBD | TBD | TBD | TBD |
| Ubuntu 24.04 | baseline-default | TBD | TBD | TBD | TBD | TBD | TBD |
| Debian 12 | baseline-default | TBD | TBD | TBD | TBD | TBD | TBD |
| Fedora 41 | baseline-default | TBD | TBD | TBD | TBD | TBD | TBD |
| RHEL 9 | baseline-default | TBD | TBD | TBD | TBD | TBD | TBD |
```

---

## Updating Baselines

### When to Update

1. **Scheduled updates:** Quarterly
2. **After major changes:** New features or optimizations
3. **OS version updates:** When new OS versions are added
4. **Infrastructure changes:** CI/CD runner upgrades

### Update Process

1. Run full performance suite on all supported OS
2. Compare with existing baselines
3. If consistent improvement (>10%), update baseline
4. Document reason for update
5. Keep historical data for trend analysis

### Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-12-28 | Initial baseline document | Claude Code |
| 1.1 | TBD | First real data collection | TBD |

---

## Performance Goals

### Primary Goals

1. **Execution Time:** Keep default operations under 10 seconds on modern hardware
2. **Memory Efficiency:** Peak memory under 50 MB for all operations
3. **Scalability:** Linear performance degradation with data size
4. **Consistency:** <20% variation across OS families

### Optimization Targets

| Priority | Target | Deadline |
|----------|--------|----------|
| **P1** | All baseline tests < 5s (local) | Q1 2026 |
| **P2** | Reduce memory footprint by 20% | Q2 2026 |
| **P3** | Parallelize independent operations | Q2 2026 |

---

## Monitoring

### Continuous Monitoring

Performance tests run automatically on:
- Every pull request
- Every commit to main branch
- Weekly scheduled runs

### Metrics Collected

- Execution time (wall clock)
- CPU time (user + system)
- Peak memory usage (RSS)
- Disk I/O (reads/writes)
- Exit code (success/failure)

### Alert Thresholds

- **Warning:** 20% slower than baseline
- **Critical:** 50% slower than baseline or exceeds "Slow" threshold

---

## Troubleshooting Performance Issues

### Common Causes

1. **Network timeouts:** Package manager mirrors unreachable
2. **Disk I/O:** Slow storage or high I/O wait
3. **CPU contention:** Other processes consuming CPU
4. **Memory pressure:** System swapping to disk

### Debugging Steps

```bash
# Run with detailed timing
bash tests/test_suite_performance.sh BENCHMARK_RUNS=5

# Check system resources during test
/usr/bin/time -v bash ./sysmaint --dry-run

# Profile with bash debugger
bash -x ./sysmaint --dry-run 2>&1 | tee debug.log
```

---

## References

- **Performance Test Suite:** `tests/test_suite_performance.sh`
- **Test Architecture:** `docs/TEST_ARCHITECTURE.md`
- **Troubleshooting:** `docs/TEST_TROUBLESHOOTING.md`

---

**Status:** DRAFT - Awaiting real test data collection

**Next Action:** Run performance suite on all supported OS and populate actual values

---

*Generated: 2025-12-28*  
*Maintained by: @Harery*
