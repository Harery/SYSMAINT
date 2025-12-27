# Expected Test Behaviors

**Version:** v1.0.0
**Last Updated:** 2025-12-27

---

## Overview

Some tests have expected behaviors that are not failures. This document lists them.

---

## Expected Behaviors

### GUI Mode in CI

**Test:** `test_suite_gui_mode.sh`

**Expected:** GUI mode tests are skipped in non-interactive environments (CI, no TTY)

**Reason:** Dialog requires interactive terminal

**Alternative:** Use `--dry-run` or `--auto` mode

---

### Docker Detection

**Test:** `test_suite_docker_detection.sh`

**Expected:** Docker container tests only run inside Docker

**Reason:** Tests verify Docker-specific behavior

---

### Platform-Specific Tests

**Test:** `test_suite_os_families.sh`

**Expected:** Tests for other OS families are skipped

**Example:** On Ubuntu, RedHat/Arch/SUSE tests are marked as skip

---

## Test Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All tests passed |
| 1 | Tests failed (unexpected) |
| 2 | Setup error |
| 127 | Required tool missing |

---

## Running Specific Tests

```bash
# Run smoke tests only
bash tests/test_suite_smoke.sh

# Run OS family tests
bash tests/test_suite_os_families.sh

# Run with debug output
DEBUG_TESTS=true bash tests/test_suite_smoke.sh
```

---

**Document Version:** v1.0.0
**Project:** https://github.com/Harery/SYSMAINT
