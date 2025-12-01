# Performance Benchmarking Guide

Name: Performance & Baselines
Purpose: Benchmark, compare, and gate regressions in CI
Need: Detect slowdowns and track performance trends across releases
Function: How to run benchmarks, manage baselines, and interpret results

> © 2025 Mohamed Elharery <Mohamed@Harery.com> • [www.harery.com](https://www.harery.com)

**Version**: 2.1.2  
**Last Updated**: November 30, 2025

[![Release](https://img.shields.io/github/v/release/Harery/SYSMAINT?label=release&color=green)](https://github.com/Harery/SYSMAINT/releases/latest)

---

<!-- Overview trimmed: Quick Start below provides immediate entry. The suite tracks time/memory and detects regressions. -->

## Quick Start

### Run Quick Benchmark (~2 minutes)

```bash
bash tests/benchmark_quick.sh
```

**Output:**
```
Critical Path Tests:
Testing minimal      ... 3.111s
Testing with-json    ... 3.252s
Testing with-upgrade ... 3.437s
Testing with-security... 3.165s
Testing full-load    ... 3.633s
```

### Run Full Benchmark Suite (~15-20 minutes)

```bash
bash tests/test_suite_performance.sh
```

This runs 25+ benchmark scenarios with 3 iterations each, generating:
- Performance statistics (avg/min/max/median)
- Memory usage tracking
- CSV report in `/tmp/sysmaint-benchmarks/`
- Automatic regression detection vs. previous run

---

## Benchmark Categories

### 1. Baseline Benchmarks

Test minimal execution overhead:

| Scenario | Flags | Purpose |
|----------|-------|---------|
| baseline-minimal | `--dry-run` | Absolute minimum execution time |
| baseline-default | `--dry-run --json-summary` | Standard dry-run with telemetry |
| baseline-with-upgrade | `--dry-run --upgrade --json-summary` | Include upgrade phase |

**Expected performance:** <3.5s average

---

### 2. Feature-Specific Benchmarks

Individual feature overhead:

| Feature | Expected Overhead |
|---------|-------------------|
| Security audit | +0.1-0.2s |
| Zombie check | +0.05-0.1s |
| Browser cache report | +0.1-0.3s |
| Kernel purge (dry) | +0.2-0.4s |
| Orphan purge (dry) | +0.3-0.5s |

---

### 3. Combined Load Benchmarks

Multiple features together:

- **Moderate load:** Upgrade + security + zombies (~3.8s)
- **Heavy load:** + kernel purge + orphan purge + browser cache (~4.5s)
- **Maximum load:** + fstrim + drop-caches + journal cleanup (~5.0s)

---

### 4. Scalability Benchmarks

Parameter scaling:

| Test | Range | Impact |
|------|-------|--------|
| Journal retention | 1d → 365d | Minimal (<0.1s) |
| Kernel count | 1 → 10 | Minimal (<0.1s) |
| Log size | 100MB → 1GB | Linear (~0.2s per 100MB) |

---

### 5. Display Mode Benchmarks

Visual output overhead:

| Mode | Overhead | Use Case |
|------|----------|----------|
| Quiet | Baseline | CI/automation |
| Dots | +0.05s | Lightweight feedback |
| Spinner | +0.1s | Interactive terminals |
| Countdown | +0.15s | User-facing operations |

---

### 6. JSON Output Benchmarks

Telemetry cost:

| Configuration | Time | Memory |
|---------------|------|--------|
| JSON disabled | Baseline | Baseline |
| JSON enabled | +0.1-0.2s | +500KB |
| Full telemetry | +0.3-0.5s | +1MB |

---

## Performance Thresholds

Configurable via environment variables:

```bash
# Default thresholds (seconds)
THRESHOLD_FAST=3.0        # Green: Fast tests
THRESHOLD_ACCEPTABLE=10.0 # Yellow: Acceptable tests
THRESHOLD_SLOW=30.0       # Red: Slow tests (warning)

# Custom thresholds
THRESHOLD_FAST=2.0 THRESHOLD_ACCEPTABLE=8.0 bash tests/test_suite_performance.sh
```

---

## Regression Detection

### Automatic Comparison

The benchmark suite automatically compares with the previous run:

```bash
bash tests/test_suite_performance.sh
```

**Output includes:**
```
Comparing with previous run: benchmark_20251115_120000.csv
✓ No performance regressions detected
```

### Manual Comparison

Compare any two benchmark reports:

```bash
bash tests/benchmark_compare.sh \
  /tmp/sysmaint-benchmarks/benchmark_BASELINE.csv \
  /tmp/sysmaint-benchmarks/benchmark_CURRENT.csv
```

**Output:**
```
Test Name                           Baseline      Current    Change     Status
────────────────────────────────────────────────────────────────────────────
baseline-minimal                      3.111s      3.089s     -0.7%     FASTER
feature-security-audit                3.265s      3.412s     +4.5%     STABLE
load-maximum                          4.987s      6.234s    +25.0%     SLOWER
```

### Regression Threshold

Default: **20% slower = regression**

```bash
# Custom threshold (10% = more sensitive)
bash tests/benchmark_compare.sh -t 10 baseline.csv current.csv
```

---

## Metrics Tracked

### Timing Metrics

- **Wall time:** Total elapsed time (user-perceived)
- **User time:** CPU time in user space
- **System time:** CPU time in kernel space

### Memory Metrics

- **Max RSS (Resident Set Size):** Peak memory usage in KB
- **Average RSS:** Mean across iterations
- **Memory growth:** Comparison vs. baseline

### Statistics

For each benchmark:
- **Average:** Mean of all iterations
- **Minimum:** Best (fastest) run
- **Maximum:** Worst (slowest) run
- **Median:** Middle value (outlier-resistant)

---

## Configuration

### Iteration Count

```bash
# Default: 3 runs per test
bash tests/test_suite_performance.sh

# Quick validation: 1 run per test
BENCHMARK_RUNS=1 bash tests/test_suite_performance.sh

# High precision: 10 runs per test
BENCHMARK_RUNS=10 bash tests/test_suite_performance.sh
```

### Results Directory

```bash
# Default: /tmp/sysmaint-benchmarks/
bash tests/test_suite_performance.sh

# Custom location
RESULTS_DIR=/var/log/benchmarks bash tests/test_suite_performance.sh
```

---

## Interpreting Results

### Good Performance Indicators

✅ **Baseline tests <3.5s:** Core execution is efficient  
✅ **Feature overhead <0.5s each:** Individual features well-optimized  
✅ **Maximum load <6s:** Combined features scale well  
✅ **Memory <50MB RSS:** Low memory footprint  
✅ **Stable across runs:** Consistent performance

### Warning Signs

⚠️ **Baseline >5s:** Core inefficiency  
⚠️ **Feature overhead >1s:** Feature needs optimization  
⚠️ **Regression >20%:** Investigate recent changes  
⚠️ **Memory >100MB RSS:** Potential memory leak  
⚠️ **High variance:** Non-deterministic behavior

---

## CI Integration

### GitHub Actions Example

```yaml
name: Performance Benchmark

on:
  pull_request:
    branches: [master]
  push:
    branches: [master]

jobs:
  benchmark:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run quick benchmark
        run: bash tests/benchmark_quick.sh
      
      - name: Run full benchmark
        run: |
          BENCHMARK_RUNS=3 bash tests/test_suite_performance.sh
      
      - name: Upload results
        uses: actions/upload-artifact@v3
        with:
          name: benchmark-results
          path: /tmp/sysmaint-benchmarks/*.csv
      
      - name: Check for regressions
        run: |
          # Compare with baseline if available
          if [ -f baseline.csv ]; then
            bash tests/benchmark_compare.sh baseline.csv \
              /tmp/sysmaint-benchmarks/benchmark_*.csv
          fi
```

---

## Troubleshooting

### Slow Performance

**Issue:** Tests consistently slower than expected

**Solutions:**
1. Check system load: `uptime`, `top`
2. Disable unnecessary services
3. Run on dedicated test machine
4. Increase BENCHMARK_RUNS for better statistics

### High Variance

**Issue:** Large min/max spread across iterations

**Causes:**
- System load fluctuations
- Background processes
- Disk I/O contention
- Network activity (if repos contacted)

**Solutions:**
- Run on idle system
- Increase iterations for stable average
- Use `nice -n -10` for priority

### Memory Spikes

**Issue:** Unexpectedly high RSS values

**Investigation:**
```bash
# Profile specific test
/usr/bin/time -v bash sysmaint --dry-run --feature 2>&1 | grep -i rss

# Check for leaks (run multiple times)
for i in {1..10}; do
  /usr/bin/time -f "%M KB" bash sysmaint --dry-run 2>&1 | tail -1
done
```

---

## Best Practices

### Before Benchmarking

1. **Idle system:** Close unnecessary applications
2. **Consistent state:** Same packages/data across runs
3. **Warm-up:** Run once to populate caches
4. **Documentation:** Note system specs in results

### During Development

1. **Baseline early:** Capture performance before changes
2. **Benchmark frequently:** Catch regressions quickly
3. **Compare commits:** Use git bisect with benchmarks
4. **Profile bottlenecks:** Use profiling tools when needed

### For Releases

1. **Full benchmark:** All scenarios, multiple iterations
2. **Document results:** Include in release notes
3. **Track trends:** Maintain historical CSV archive
4. **Set SLOs:** Define acceptable performance ranges

---

## Advanced Usage

### Custom Benchmarks

Add to `test_suite_performance.sh`:

```bash
# New feature benchmark
run_benchmark "feature-custom-thing" --dry-run --custom-feature --json-summary

# Stress test
run_benchmark "stress-parallel" --dry-run --parallel --upgrade \
  --security-audit --check-zombies --json-summary
```

### Profiling Integration

```bash
# CPU profiling with perf
perf record -g bash sysmaint --dry-run --upgrade
perf report

# Memory profiling with valgrind
valgrind --tool=massif bash sysmaint --dry-run
ms_print massif.out.*
```

### Continuous Monitoring

```bash
# Cron job for nightly benchmarks
0 2 * * * cd /opt/sysmaint && \
  BENCHMARK_RUNS=5 bash tests/test_suite_performance.sh && \
  bash tests/benchmark_compare.sh \
    /var/benchmarks/baseline.csv \
    /tmp/sysmaint-benchmarks/benchmark_*.csv
```

---

## Performance Baselines

### Official Baseline Files

Performance baselines are maintained in the `benchmarks/` directory:

| File | Version | Date | Purpose |
|------|---------|------|---------|
| `baseline_v2.1.1.csv` | 2.1.1 | 2025-11-15 | Current production baseline |
| `baseline_v2.2.0.csv` | 2.2.0 | Future | Next release target baseline |

**Baseline Update Policy:**
- Baselines are updated at each minor/major release
- Patch releases use existing minor version baseline
- Regression tests compare against current version baseline

### Current Performance (v2.1.1)

Measured on reference hardware (4 CPU cores, 8GB RAM, SSD):

| Metric | Value | Status |
|--------|-------|--------|
| Baseline (minimal) | ~3.1s | ✅ Fast |
| Standard (with JSON) | ~3.3s | ✅ Fast |
| Full features | ~3.6s | ✅ Fast |
| Maximum load | ~5.0s | ✅ Acceptable |
| Memory footprint | ~30MB RSS | ✅ Efficient |

### Baseline Maintenance

```bash
# Generate new baseline after performance improvements
BENCHMARK_RUNS=5 bash tests/test_suite_performance.sh
cp /tmp/sysmaint-benchmarks/current_run.csv benchmarks/baseline_v2.1.1.csv

# Compare with previous baseline
bash tests/benchmark_compare.sh \
  benchmarks/baseline_v2.1.1.csv \
  /tmp/sysmaint-benchmarks/current_run.csv

# Archive old baselines for historical tracking
git add benchmarks/baseline_v*.csv
git commit -m "Update performance baseline for v2.1.1"
```

### Future Targets

| Version | Target | Improvement |
|---------|--------|-------------|
| v2.2.0 | <3.0s baseline | -3% |
| v2.3.0 | <4.5s maximum | -10% |
| v3.0.0 | <2.5s baseline | -20% |

---

## Summary

✅ **25+ benchmark scenarios** covering all major features  
✅ **Automated regression detection** with 20% threshold  
✅ **Statistical analysis** (avg/min/max/median)  
✅ **Memory usage tracking** via RSS  
✅ **CSV reports** for historical analysis  
✅ **Quick validation** in ~2 minutes  
✅ **Full suite** completes in ~15-20 minutes  
✅ **CI-ready** with exit codes for failures  

---

<div align="center">

**[← Back to README](../README.md)** • **[Features →](../FEATURES.md)**

**MIT Licensed** • **[www.harery.com](https://www.harery.com)**

</div>
