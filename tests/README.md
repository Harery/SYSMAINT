# Test Suite Overview

> Note: This overview has moved under `docs/TEST_COVERAGE.md` and is indexed in `docs/INDEX.md`. Prefer those as the single source of truth.

> © 2025 Mohamed Elharery <Mohamed@Harery.com>

sysmaint v2.1.1 ships consolidated bash test suites (plus JSON validation) that cover every documented scenario. Each suite forces `DRY_RUN=true`, so they are safe to execute anywhere.

## Test Suites

### `test_suite_smoke.sh` — 65 tests (includes profiles)

Baseline + advanced smoke coverage combining the former `smoke.sh`, `smoke_extended.sh`, and `smoke_ultra.sh` flows.

- **Structure:** Basic (6), Extended (filesystems, kernel/journal, browser cache, snap, tmp, desktop guard), Advanced (auto/parallel combos, rapid cycles, audit/zombie guard mixes), Profiles (5 preset tests via `sysmaint profiles` subcommand).
- **Purpose:** Fast regression net for the most common flag mixes.
- **Runtime:** ~3 minutes.
- **Run:**
	```bash
	bash tests/test_suite_smoke.sh
	```

---

### `test_suite_edge.sh` — 67 tests

Argument parser torture suite that merges `args_edge.sh`, `edge_extended.sh`, and `edge_advanced.sh`.

- **Coverage:** help/version, non-root dry-run paths, ordering permutations, duplicate/contradicting flags, stress bundles, failure expectations.
- **Runtime:** ~3 minutes.
- **Run:**
	```bash
	bash tests/test_suite_edge.sh
	```

---

### `test_suite_combos.sh` — 28 tests

Feature combination gallery validating advanced flag interactions.

# Tests (Pointer)

This file is intentionally minimal to keep the repo lean.

- Full test documentation: `docs/TEST_COVERAGE.md`
- Quick runs:
  ```bash
  bash tests/test_suite_smoke.sh
  bash tests/test_suite_edge.sh
  bash tests/test_suite_combos.sh
  bash tests/test_json_validation.sh
  ```

Artifacts live in `/tmp/system-maintenance/`. JSON schema: `docs/schema/sysmaint-summary.schema.json`.
- **Mechanics:** Prepends `tests/mocks/realmodesandbox/bin` to `PATH`, sets `SYSMAINT_FAKE_ROOT=1`, and lets the shimbed commands absorb every destructive action.
