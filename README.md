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

## Where Next

- Read: `docs/INDEX.md` (map)
- Tests: `docs/TEST_COVERAGE.md`
- Security: `docs/SECURITY.md`
- Performance: `docs/PERFORMANCE.md`
 - Changelog: `CHANGELOG.md`

## Contact

Author: Mohamed Elharery <Mohamed@Harery.com>
MIT Licensed. Safe to run dry-first. Contributions welcome.
