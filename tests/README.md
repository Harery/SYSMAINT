# Test Suite

Comprehensive test coverage for **sysmaint** (v2.1.1).

## Test scripts

### `smoke.sh`

Quick baseline dry-run tests with several argument combinations. Validates JSON output and checks for basic execution success.

**Run:**

```bash
bash tests/smoke.sh
```

**Coverage:**
- Default run
- `--upgrade` final phase
- Color modes (never, always)
- Browser cache report
- Zombie detection and security audit

**Exit codes:**
- 0 = pass
- Non-zero = fail

---

### `dryrun_fullcycle.sh`

**Full-cycle progressive test suite** covering all available flags in stages:

1. **Default:** No flags
2. **Fixed combos:** Stable multi-flag combinations (upgrade, simulate-upgrade, audits, browser cache)
3. **Optional toggles:** Individual feature flags tested one-by-one (fstrim, drop-caches, kernel purge, orphan purge, snap/flatpak options, progress modes, lock settings, log truncation, parallel exec)
4. **Autopilot variants:** `--auto`, custom reboot delays
5. **Broad combined:** Most optional features together (avoiding conflicts)
6. **Negative sweep:** Disabling most defaults with `--no-*` flags

**Run:**

```bash
bash tests/dryrun_fullcycle.sh
```

**What it does:**
- Each case runs `sysmaint` with `DRY_RUN=true` and `JSON_SUMMARY=true`
- Validates the resulting JSON against the schema after each run
- Non-destructive: all runs are dry-run only
- Logs results inline (`[result] exit=<code>`, `JSON schema validation: OK`)

**Expected duration:** ~3-5 minutes (40+ test cases).

---

### `args_edge.sh`

Edge-case argument parsing and non-root dry-run validation. Tests:
- Help and version flags
- Non-root user + `--dry-run` combinations
- Argument order independence
- Early exit paths (e.g., `--simulate-upgrade`)

**Run:**

```bash
bash tests/args_edge.sh
```

**Expected output:** `Passed 6/6` (or similar count).

---

### `validate_json.sh`

JSON schema validation wrapper. Runs a dry-run to produce JSON, then validates against the schema.

**Run:**

```bash
bash tests/validate_json.sh
```

**Manual validation:**

```bash
python3 tests/validate_json.py docs/schema/sysmaint-summary.schema.json /tmp/system-maintenance/sysmaint_<RUN_ID>.json
```

---

## Running all tests

From the repo root:

```bash
bash tests/smoke.sh && \
bash tests/args_edge.sh && \
bash tests/validate_json.sh && \
bash tests/dryrun_fullcycle.sh
```

Or use the CI workflow locally (requires `act` or push to trigger GitHub Actions):

```bash
# View the workflow
cat .github/workflows/dry-run.yml
```

---

## Test data and artifacts

- **JSON summaries:** Written to `/tmp/system-maintenance/sysmaint_*.json` during runs (DRY_RUN=true ensures no changes).
- **Logs:** Each run creates a log file in `/tmp/system-maintenance/sysmaint_*.log`.
- **Schema:** `docs/schema/sysmaint-summary.schema.json` defines the expected JSON structure.

---

## CI integration

All tests run automatically on push/PR via `.github/workflows/dry-run.yml`:

- **dry-run job (matrix):** Runs smoke tests with various flag combinations.
- **full-cycle job:** Executes the full-cycle suite after the matrix passes.
- **Schema validation:** Validates JSON output against the schema in each job.
- **Edge tests:** Runs argument edge-case validation.

---

## Adding new tests

To add a new test case to the full-cycle suite:

1. Edit `tests/dryrun_fullcycle.sh`
2. Add a new `run_case` call with descriptive name and flags
3. Run the suite locally to verify
4. Commit and push (CI will validate)

Example:

```bash
run_case "new feature test" --new-flag --other-flag
```

---

## Notes

- All test scripts are designed to be safe and non-destructive (DRY_RUN=true).
- JSON schema validation requires `python3` and the `jsonschema` module (`pip install jsonschema` or `pipx install jsonschema`).
- If a test fails, check the log file in `/tmp/system-maintenance/` for details.
- The full-cycle suite may produce warnings for transient file access issues (e.g., JSON not yet closed); these are non-fatal and retry logic handles them.
