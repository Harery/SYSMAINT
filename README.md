# sysmaint (v2.1.1)

A safe, scriptable Ubuntu/Debian maintenance runner: APT + Snap updates, cleanup phases, rich JSON telemetry, unattended/autopilot mode, and optional security + scanner integrations.

**License:** MIT  •  **Status:** Production Ready  •  **Test Suites:** See `docs/TEST_COVERAGE.md`

## Quick Start

```bash
# Dry-run with JSON telemetry (safe preview)
DRY_RUN=true JSON_SUMMARY=true ./sysmaint --dry-run --json-summary

# Unattended weekly maintenance
sudo ./sysmaint --auto --auto-reboot-delay 45 --json-summary

# Include final upgrade phase
sudo ./sysmaint --upgrade
```

## Embedded Subcommands

Profiles and scanners are now first-class subcommands (no extra scripts):

```bash
./sysmaint profiles --profile desktop --print-command   # Preview
./sysmaint profiles --profile standard --yes            # Run without prompt
LYNIS_MIN_SCORE=80 RKHUNTER_MAX_WARNINGS=5 ./sysmaint scanners
```

## Tier 1 Profiles

| Key | Purpose | Highlights | Est. Time | Risk |
|-----|---------|-----------|-----------|------|
| minimal | Safest telemetry preview | `--dry-run --json-summary` | ~2m | None |
| standard | Weekly unattended flow | `--auto --json-summary --auto-reboot-delay 45` | ~5m | Low |
| desktop | Desktop cleanup + visuals | `--browser-cache-report --browser-cache-purge --progress=spinner` | ~6m | Med |
| server | Hardened server maintenance | `--upgrade --security-audit --check-zombies --auto` | ~8m | Med |
| aggressive | Max reclamation | `--upgrade --purge-kernels --keep-kernels=2 --orphan-purge --fstrim --drop-caches` | ~10m | High |

## Common Flags

- `--upgrade` final upgrade phase
- `--color=auto|always|never` output color control
- `--check-zombies` zombie process scan
- `--security-audit` permission audit (shadow/gshadow/sudoers)
- `--browser-cache-report|--browser-cache-purge` browser cache telemetry/actions
- `--purge-kernels --keep-kernels=N` kernel cleanup
- `--orphan-purge` orphaned packages
- `--fstrim` SSD TRIM
- `--drop-caches` page cache clear
- `--auto --auto-reboot-delay N` unattended + controlled reboot
- `--progress=spinner|dots|bar|quiet|adaptive` progress UI selection

Disable defaults with `--no-*` (e.g. `--no-snap`, `--no-clear-tmp`, `--no-journal-vacuum`).

## Exit Codes

sysmaint uses specific exit codes to indicate different outcomes:

| Code | Meaning | Description |
|------|---------|-------------|
| `0` | Success | Maintenance completed successfully, no issues |
| `1` | General Error | OS check failure, log directory creation failure, or other errors |
| `10` | Repository Issues | Repository validation failures detected |
| `20` | Missing Keys | APT public keys are missing |
| `30` | Failed Services | Systemd services in failed state detected |
| `75` | Lock Timeout | Could not acquire lock (another instance running) |
| `100` | Reboot Required | Maintenance completed but system reboot is required |

**Note**: Exit code `100` indicates successful completion when a reboot is needed. In scripts, treat both `0` and `100` as success states.

## JSON Summary

Enable via `JSON_SUMMARY=true` or `--json-summary`. Writes to `/tmp/system-maintenance/sysmaint_<RUN_ID>.json` including:
- Phase timings, disk deltas, system metadata
- Upgrade / audit / zombie / browser cache telemetry
- Autopilot and reboot recommendation fields
- Color mode, dry-run indicator, log truncation status

Schema: `docs/schema/sysmaint-summary.schema.json`

## Defaults Snapshot

| Area | Default |
|------|---------|
| APT | update, upgrade, autoremove, autoclean |
| Snap/Flatpak | Snap refresh; Flatpak if present |
| Journal | Vacuum 7d / 500M |
| /tmp | Age-based cleanup |
| Desktop guard | Enabled |
| Zombie check | Enabled |
| Browser cache | Disabled (report/purge opt-in) |
| Final upgrade | Disabled (use `--upgrade`) |

## Systemd Timer (Weekly)

```bash
sudo install -Dm755 sysmaint /usr/local/sbin/sysmaint
sudo install -Dm644 packaging/systemd/sysmaint.service /etc/systemd/system/sysmaint.service
sudo install -Dm644 packaging/systemd/sysmaint.timer /etc/systemd/system/sysmaint.timer
sudo systemctl daemon-reload
sudo systemctl enable --now sysmaint.timer
```
Optional env file: `/etc/sysmaint/sysmaint.env` (e.g. `LOG_MAX_SIZE_MB=20`).

## Security & Scanners

- Built-in: `--security-audit` (permission checks) → see `docs/SECURITY.md`
- External: lynis + rkhunter via `./sysmaint scanners` (threshold env vars: `LYNIS_MIN_SCORE`, `RKHUNTER_MAX_WARNINGS`)

## Performance

Benchmark + regression gate integrated. Baselines and usage in `docs/PERFORMANCE.md`.

Quick check:
```bash
BENCHMARK_RUNS=1 bash tests/test_suite_performance.sh
```

## Minimal Usage Patterns

```bash
# Safe exploration
DRY_RUN=true JSON_SUMMARY=true ./sysmaint --dry-run --json-summary

# Hardened server run
sudo ./sysmaint --upgrade --security-audit --check-zombies --json-summary

# Desktop cleanup (preview then run)
./sysmaint profiles --profile desktop --print-command
./sysmaint profiles --profile desktop --yes
```

## Migration Notes

Previously separate scripts `sysmaint_profiles.sh` and `sysmaint_scanners.sh` removed. Use embedded subcommands. Legacy full-cycle suite replaced by `test_suite_combos.sh`.

## Documentation Map

**Primary Docs** (single purpose per file):
- Testing & Coverage → `docs/TEST_COVERAGE.md` (suites, counts, JSON schema validation)
- Security Hardening → `docs/SECURITY.md` (audit, best practices, lynis/rkhunter)
- Performance & Baselines → `docs/PERFORMANCE.md` (benchmarks, regression gate, CSV outputs)
- Changelog → `CHANGELOG.md` (release notes, SemVer)

**Topic Ownership**:
- Core usage, flags, examples → this README
- Test execution, coverage matrix → `docs/TEST_COVERAGE.md`
- Security audit details, permissions → `docs/SECURITY.md`
- Benchmarks, performance gate → `docs/PERFORMANCE.md`

## Contact

Author: Mohamed Elharery <Mohamed@Harery.com>
MIT Licensed. Safe to run dry-first. Contributions welcome.

## Modularization Summary (2025-11-16)

- Extracted common utilities, JSON generation, and subcommands into `lib/` while keeping 100% backward compatibility.
- Merged progress UI into `lib/utils.sh` and removed `lib/progress.sh` to reduce file count.
- Removed on-disk monolith backup (`sysmaint.monolith`) since Git history preserves it.
- All suites remain green: smoke (65), edge (67), JSON (2), security (36), governance (18), compliance (32), scanners (10), sandbox (5).
