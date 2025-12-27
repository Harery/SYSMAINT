# Test Suite

## Quick Start

```bash
# Run all tests (safe - uses DRY_RUN=true)
bash tests/test_suite_smoke.sh
```

## Test Suites

| Suite | Purpose |
|-------|---------|
| `test_suite_smoke.sh` | Core functionality |
| `test_suite_edge.sh` | Edge cases |
| `test_suite_security.sh` | Security checks |
| `test_suite_compliance.sh` | Standards |
| `test_suite_governance.sh` | Exit codes |
| `test_suite_performance.sh` | Benchmarks |
| `test_json_validation.sh` | JSON validation |
| `test_suite_scanners.sh` | External tools |
| `test_suite_combos.sh` | Flag combinations |
| `test_gui_mode.sh` | GUI interface |

## Run Full Suite

```bash
for suite in smoke edge security compliance governance performance scanners combos; do
  bash tests/test_suite_${suite}.sh
done
```

## Artifacts

| Location | Content |
|----------|---------|
| `/tmp/system-maintenance/` | JSON summaries & logs |
| `docs/schema/sysmaint-summary.schema.json` | JSON schema |

## Safety

- All tests use `DRY_RUN=true` — no system changes
- Mock binaries in `tests/mocks/realmodesandbox/bin/`
