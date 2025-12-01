# 🧪 Test Suite

> © 2025 Mohamed Elharery <Mohamed@Harery.com> • [www.harery.com](https://www.harery.com)

[![Tests](https://img.shields.io/badge/tests-246%20passing-brightgreen)](https://github.com/Harery/SYSMAINT)
[![Coverage](https://img.shields.io/badge/coverage-100%25-brightgreen)](https://github.com/Harery/SYSMAINT)

---

## 🚀 Quick Start

```bash
# Run all tests (safe - uses DRY_RUN=true)
bash tests/test_suite_smoke.sh
```

---

## 📋 Test Suites

| Suite | Tests | Purpose |
|:------|:-----:|:--------|
| 🔥 `test_suite_smoke.sh` | 65 | Core functionality & profiles |
| 🔀 `test_suite_edge.sh` | 67 | Edge cases & argument parsing |
| 🔐 `test_suite_security.sh` | 36 | Security & permissions |
| 📋 `test_suite_compliance.sh` | 32 | Standards compliance |
| 🏛️ `test_suite_governance.sh` | 18 | Exit codes & versioning |
| ⚡ `test_suite_performance.sh` | ~20 | Benchmarks |
| 📄 `test_json_validation.sh` | 4 | JSON schema validation |
| 🔌 `test_suite_scanners.sh` | 10 | External tool integration |

**Total: 246 tests**

---

## 🔧 Run Individual Suites

```bash
# Quick smoke test
bash tests/test_suite_smoke.sh

# Full test run
for suite in smoke edge security compliance governance performance; do
  bash tests/test_suite_${suite}.sh
done
```

---

## 📁 Artifacts

| Location | Content |
|:---------|:--------|
| `/tmp/system-maintenance/` | JSON summaries & logs |
| `docs/schema/sysmaint-summary.schema.json` | JSON schema |
| `benchmarks/` | Performance baselines |

---

## 🛡️ Safety

All tests run with `DRY_RUN=true` — no system changes are made.

Mock binaries in `tests/mocks/realmodesandbox/bin/` intercept destructive commands.

---

📖 **Full documentation:** [FEATURES.md](../FEATURES.md) → Test Coverage Matrix
