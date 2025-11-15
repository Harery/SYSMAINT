# Test Suite Overview

> © 2025 Mohamed Elharery <Mohamed@Harery.com>

sysmaint v2.1.1 ships three consolidated bash suites (plus a JSON validator pair) that cover every documented scenario. Each suite forces `DRY_RUN=true`, so they are safe to execute anywhere.

## Test Suites

### `test_suite_smoke.sh` — 60 tests

Baseline + advanced smoke coverage combining the former `smoke.sh`, `smoke_extended.sh`, and `smoke_ultra.sh` flows.

- **Structure:** Basic (6), Extended (filesystems, kernel/journal, browser cache, snap, tmp, desktop guard), Advanced (auto/parallel combos, rapid cycles, audit/zombie guard mixes).
- **Purpose:** Fast regression net for the most common flag mixes.
- **Runtime:** ~3 minutes.
- **Run:**
	```bash
	bash tests/test_suite_smoke.sh
	```

---

### `test_suite_fullcycle.sh` — 97 tests

Full progressive lifecycle suite (formerly `dryrun_fullcycle.sh`, `fullcycle_advanced.sh`, and `combo_advanced.sh`).

- **Phases:**
	1. Defaults + upgrade/autopilot basics
	2. Individual feature toggles (fstrim, drop-caches, kernel purge, orphan/orphan, snap/flatpak, locks/logging)
	3. Progress + visual modes (color, progress styles, animation)
	4. Advanced operations (desktop guard, zombie scan, audit sweeps)
	5. Combined desktop/server mixes
	6. Negative sweeps using `--no-*` flags
	7. Feature combination gallery (12 curated combos)
- **Assertions:** JSON schema validation plus targeted field checks (`final_upgrade_enabled`, `desktop_guard_enabled`, `auto_mode`, etc.).
- **Runtime:** ~6 minutes.
- **Run:**
	```bash
	bash tests/test_suite_fullcycle.sh
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

### `test_suite_realmode_sandbox.sh` — 5 tests

Minimal "real-mode" sanity suite that keeps `DRY_RUN` disabled while safely intercepting privileged binaries.

- **Mechanics:** Prepends `tests/mocks/realmodesandbox/bin` to `PATH`, sets `SYSMAINT_FAKE_ROOT=1`, and lets the shimbed commands absorb every destructive action.
- **Purpose:** Proves core flows (default, upgrade, auto, browser cache, audit/zombie) succeed without `--dry-run`, validating the final JSON fields (`dry_run_mode=false`, `final_upgrade_enabled`, etc.).
- **Runtime:** ~2 minutes.
- **Run:**
	```bash
	bash tests/test_suite_realmode_sandbox.sh
	```

> ⚠️ The sandbox is for CI/development only. Never set `SYSMAINT_FAKE_ROOT=1` or use the shimbed PATH on production machines.
### `test_suite_security.sh` — 32 tests

Security audit feature validation suite.

- **Coverage:** Security audit enable/disable, permission checks for shadow/gshadow/sudoers/sudoers.d, JSON output validation, feature combinations, governance checks, compliance frameworks (PCI-DSS, HIPAA, SOC 2, ISO 27001, GDPR, CIS, FedRAMP, NIST).
- **Purpose:** Validate security hardening features introduced in Stage 1.5.
- **Runtime:** ~2 minutes.
- **Run:**
	```bash
	bash tests/test_suite_security.sh
	```

---

### `test_suite_governance.sh` — 15 tests

Governance and audit trail validation suite.

- **Coverage:** Audit log creation, timestamp tracking, system context capture, command line recording, change management, privileged operations, lifecycle markers, policy enforcement, compliance mode, multi-user context, separation of duties.
- **Purpose:** Validate governance telemetry and audit trail completeness.
- **Runtime:** ~1 minute.
- **Run:**
	```bash
	bash tests/test_suite_governance.sh
	```

---

### `test_suite_compliance.sh` — 32 tests

Regulatory compliance framework validation suite.

- **Coverage:** 8 frameworks with 4 tests each:
  - **PCI-DSS:** Password file permissions, audit trails, record elements, system hardening
  - **HIPAA:** Audit controls, risk assessment, access control, security logging
  - **SOC 2:** Change management, system monitoring, logical access, user access audit
  - **ISO 27001:** Access controls, event logging, change management, privileged access
  - **GDPR:** Security measures, system resilience, processing records, data integrity
  - **CIS Benchmarks:** SSH config, password policy, file permissions, audit logging
  - **FedRAMP:** Account management, auditable events, change control, flaw remediation
  - **NIST 800-53:** Maintenance procedures (MA-2), audit records (AU-3), least privilege (AC-6), baseline config (CM-2)
- **Purpose:** Validate alignment with regulatory requirements.
- **Runtime:** ~2 minutes.
- **Run:**
	```bash
	bash tests/test_suite_compliance.sh
	```

---

### `test_suite_performance.sh` — 25+ benchmarks

Automated performance benchmarking suite with regression detection.

- **Coverage:**
  - **Baseline:** Minimal, default, with-upgrade configurations
  - **Features:** Security audit, zombie check, browser cache, kernel purge, orphan purge
  - **Load:** Moderate, heavy, maximum feature combinations
  - **Scalability:** Journal retention (1d/30d/365d), kernel counts (1/5/10)
  - **Display modes:** Quiet, dots, spinner, countdown
  - **JSON overhead:** Disabled, enabled, full telemetry
- **Metrics tracked:** Wall time, memory usage (RSS), performance thresholds
- **Regression detection:** Automatic comparison with previous runs (20% threshold)
- **Output:** CSV reports, performance rankings, historical comparison
- **Runtime:** ~15-20 minutes (3 iterations per test by default).
- **Run:**
	```bash
	# Full benchmark suite (3 runs per test)
	bash tests/test_suite_performance.sh
	
	# Quick benchmark (1 run per test, ~2 min)
	bash tests/benchmark_quick.sh
	
	# Compare two benchmark runs
	bash tests/benchmark_compare.sh /tmp/sysmaint-benchmarks/benchmark_OLD.csv /tmp/sysmaint-benchmarks/benchmark_NEW.csv
	```
- **Configuration:**
	```bash
	# Adjust number of iterations per test
	BENCHMARK_RUNS=5 bash tests/test_suite_performance.sh
	
	# Set custom thresholds (in seconds)
	THRESHOLD_FAST=2.0 THRESHOLD_ACCEPTABLE=8.0 bash tests/test_suite_performance.sh
	```

---

---

### JSON Schema Helpers

- `validate_json.sh`: convenience wrapper that triggers a dry run then validates the most recent summary.
- `validate_json.py`: generic validator (requires `jsonschema`).
- `test_json_negative.sh`: crafts malformed JSON to ensure the validator fails loudly.

```bash
bash tests/validate_json.sh
python3 tests/validate_json.py docs/schema/sysmaint-summary.schema.json /tmp/system-maintenance/sysmaint_<RUN_ID>.json
bash tests/test_json_negative.sh
```

---

### Tier 1 profile helper (`test_profiles_tier1.sh`)

Sanity checks for `sysmaint_profiles.sh` (Stage 2 Tier 1) to ensure presets emit the expected CLI flags.

- **What it covers:**
	- Minimal preview profile always sets `--dry-run --json-summary`.
	- Server profile toggles security audit + zombie checks.
	- Extra CLI flags are forwarded to the generated command.
- **Run:**
	```bash
	bash tests/test_profiles_tier1.sh
	```

---

### Debian package validation (`test_package_build.sh`)

Builds the `.deb` inside a temporary directory using `dpkg-buildpackage` and verifies the resulting artifact with `dpkg-deb --info`.

- Installs no files on the host—the temporary tree is deleted after the check.
- Requires standard packaging tools (`dpkg-buildpackage`, `dpkg-deb`, `rsync`).
- Run locally or via CI:
	```bash
	bash tests/test_package_build.sh
	```

---

## Running all tests

From the repo root:

```bash
bash tests/test_suite_smoke.sh && \
bash tests/test_suite_edge.sh && \
bash tests/test_suite_fullcycle.sh && \
bash tests/validate_json.sh
```

Tip: suites print numbered banners (e.g., `Phase 3 (Toggle Arc) — Test 44/97`). If a counter drifts, update the script before merging.

---

## Test data and artifacts

- **JSON summaries:** Written to `/tmp/system-maintenance/sysmaint_*.json` during runs (DRY_RUN=true ensures no changes).
- **Logs:** Each run creates a log file in `/tmp/system-maintenance/sysmaint_*.log`.
- **Schema:** `docs/schema/sysmaint-summary.schema.json` defines the expected JSON structure.

---

## CI integration

`.github/workflows/dry-run.yml` orchestrates:

- **dry-run matrix:** Invokes the smoke + edge suites across supported shells.
- **full-cycle job:** Runs `test_suite_fullcycle.sh` once all validators finish.
- **JSON check:** Executes `validate_json.sh` to keep schema drift in check.

---

## Adding new tests

1. Choose the closest suite:
	- `test_suite_smoke.sh` → quick flag coverage / regression
	- `test_suite_edge.sh` → parser/validation behaviors
	- `test_suite_fullcycle.sh` → JSON assertions + staged flows
2. Add a `run_test`, `test_ok`, or `run_case` entry with a descriptive label and flags.
3. Keep counters and section headers accurate.
4. Run the suite locally before pushing; CI will rerun it.

Example:

```bash
run_case "upgrade-with-progressive-flag" --upgrade --progress=bar --dry-run
```

---

## Troubleshooting

- **Where did my artifacts go?** Replays live in `/tmp/system-maintenance`. Purge stale files with `rm -rf /tmp/system-maintenance/sysmaint_*`. The packaging test keeps everything in a temporary directory that is deleted automatically.
- **Missing Python deps:** Install `pipx install jsonschema` (or `python3 -m pip install --user jsonschema`) before running the schema or negative tests.
- **Packaging toolchain:** `tests/test_package_build.sh` expects `dpkg-buildpackage`, `dpkg-deb`, `lintian`, and `rsync`. On Ubuntu runners, run `sudo apt-get install -y debhelper devscripts lintian rsync` first.
- **sandbox suite warnings:** The real-mode sandbox fakes privileged binaries via `tests/mocks/realmodesandbox/bin`. If you see "command not found" errors, ensure that directory still contains the shim executables and that `SYSMAINT_FAKE_ROOT=1` is set.

---

## Notes

- All test scripts are designed to be safe and non-destructive (DRY_RUN=true).
- JSON schema validation requires `python3` and the `jsonschema` module (`pip install jsonschema` or `pipx install jsonschema`).
- If a test fails, check the log file in `/tmp/system-maintenance/` for details.
- The full-cycle suite may produce warnings for transient file access issues (e.g., JSON not yet closed); these are non-fatal and retry logic handles them.

## Historical scripts

`smoke.sh`, `smoke_extended.sh`, `smoke_ultra.sh`, `args_edge.sh`, `edge_extended.sh`, `edge_advanced.sh`, `dryrun_fullcycle.sh`, `fullcycle_advanced.sh`, `comprehensive_rapid.sh`, and `combo_advanced.sh` were merged into the suites above. Refer to the `v2.1.1-pre-consolidation` tag if you ever need their exact layouts.
