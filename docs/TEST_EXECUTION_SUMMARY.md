# SYSMAINT Test Execution Summary

**Version:** v1.0.0
**Last Updated:** 2025-12-27

---

## Quick Reference

### Run All Tests

```bash
cd /path/to/sysmaint
bash tests/test_suite_smoke.sh
```

### Run Specific Test Suite

```bash
bash tests/test_suite_os_families.sh
```

### Run with Debug Output

```bash
DEBUG_TESTS=true bash tests/test_suite_smoke.sh
```

---

## Test Suites

| Suite | Command |
|-------|---------|
| Smoke tests | `bash tests/test_suite_smoke.sh` |
| Functions | `bash tests/test_suite_functions.sh` |
| Security | `bash tests/test_suite_security.sh` |
| Performance | `bash tests/test_suite_performance.sh` |
| OS Families | `bash tests/test_suite_os_families.sh` |
| GUI Mode | `bash tests/test_suite_gui_mode.sh` |
| JSON Validation | `bash tests/test_suite_json_validation.sh` |

---

## Result Interpretation

```
[PASS] - Test passed
[FAIL] - Test failed (investigate)
[SKIP] - Test skipped (expected on some platforms)
```

---

## Getting Help

If tests fail:

1. Run with `DEBUG_TESTS=true`
2. Check `sysmaint --verbose` output
3. Report at: https://github.com/Harery/SYSMAINT/issues

---

**Document Version:** v1.0.0
**Project:** https://github.com/Harery/SYSMAINT
