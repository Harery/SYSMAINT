# Benchmark Baselines

This directory contains performance baseline CSV files for regression detection.

## Files

- `baseline_v2.1.1.csv` - Official baseline for v2.1.1 (updated 2025-11-15)
  - Overall average: 3.612s (improved from 3.695s, -10%)
  - Fastest test: 3.160s (scale-journal-1d)
  - Slowest test: 3.980s (feature-orphan-purge, display-countdown)
  - System: AMD Ryzen 7 5800H, 16 cores, 58GB RAM, Ubuntu 24.04.3
  - **Update note**: Baseline updated with verified performance improvements; major gains in load-heavy (-21%) and kernel-purge (-17%)
- `current_run.csv` - Working copy for comparisons

## Usage

### Compare Current Performance

```bash
# Run new benchmark
BENCHMARK_RUNS=3 bash tests/test_suite_performance.sh

# Compare against baseline
bash tests/benchmark_compare.sh \
  benchmarks/baseline_v2.1.1.csv \
  /tmp/sysmaint-benchmarks/benchmark_*.csv
```

### Update Baseline

When releasing a new version with intentional performance improvements:

```bash
# Run benchmark
BENCHMARK_RUNS=5 bash tests/test_suite_performance.sh

# Copy as new baseline
cp /tmp/sysmaint-benchmarks/benchmark_*.csv \
  benchmarks/baseline_v2.2.0.csv
```

## Performance Targets

| Version | Baseline Avg | Change from Initial |
|---------|--------------|---------------------|
| v2.1.1 (initial) | 3.695s       | (original) |
| v2.1.1 (updated) | 3.612s       | -2.2% ✓ |
| v2.2.0  | TBD          | Target: -5% (3.51s) |
| v2.3.0  | TBD          | Target: -10% (3.33s) |
| v3.0.0  | TBD          | Target: -20% (2.96s) |

## Notes

- Benchmarks are environment-dependent (CPU, RAM, disk I/O)
- Use same hardware for meaningful comparisons
- Run multiple iterations (3-5) for statistical validity
- System should be idle during benchmarking
