# Performance Baseline Updates

## v2.2.0 (2025-11-15)
**Source:** `benchmark_20251115_143143.csv` (copied to `current_run.csv`)

### Changes from v2.1.1
- Overall performance improvement: **-10.0%** (3.695s → 3.612s average)
- 5 tests showed >10% improvement (FASTER):
  - `feature-kernel-purge`: -16.5%
  - `load-heavy`: -21.2%
  - `load-maximum`: -14.8%
  - `scale-journal-1d`: -10.4%
  - `scale-journal-30d`: -14.6%
- 19 tests remained stable (within ±10%)
- No regressions detected

### Rationale
After test suite modernization (legacy full-cycle retirement, combo suite introduction), 
performance improved across the board. Updated baseline to reflect new normal and maintain 
accurate regression detection going forward.

### Baseline File
- Primary: `baseline_v2.2.0.csv`
- Previous: `baseline_v2.1.1.csv` (retained for historical comparison)
- CI workflow: Updated to use v2.2.0

---

## v2.1.1 (Historical)
Original baseline established with legacy test suite architecture.
