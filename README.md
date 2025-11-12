# sysmaint (v2.1.0)

A safe, scriptable Ubuntu/Debian maintenance runner: APT + Snap updates, cleanup phases, rich JSON telemetry, and unattended/autopilot mode.

## Quick start

Preview (no changes, JSON summary):

```bash
DRY_RUN=true JSON_SUMMARY=true ./sysmaint --dry-run --json-summary
```

Autopilot with safe defaults and auto-reboot delay:

```bash
sudo ./sysmaint --auto --auto-reboot-delay 45 --json-summary
```

Run with optional final upgrade phase:

```bash
sudo ./sysmaint --upgrade
```

## Notable flags

- `--upgrade` — Final apt full-upgrade near the end (opt-in). JSON: `final_upgrade_enabled` and counts.
- `--color <auto|always|never>` — Control ANSI color on terminal output. JSON: `color_mode`.
- `--check-zombies` / `--no-check-zombies` — Enable/disable zombie process scan. JSON: `zombie_count`, `zombie_processes`.
- `--security-audit` — Minimal permissions audit (shadow/gshadow/sudoers), JSON reports `shadow_perms_ok`, etc.
- `--browser-cache-report` — Report Firefox/Chromium/Chrome cache sizes.
- `--browser-cache-purge` — Purge browser caches (cache dirs only; dry-run recommended first).
- `--log-max-size-mb <N>` — Truncate log to keep last tail if it grows beyond N MB. JSON: `log_truncated`, sizes.
- `--auto` / `--auto-reboot-delay <S>` — Autopilot with timed reboot when required. JSON: `auto_mode`, `auto_reboot_delay_seconds`.

Common safety toggles:
- `--purge-kernels`, `--keep-kernels <N>`, `--orphan-purge`, `--fstrim`, `--drop-caches`.

## Copy–paste examples

- Weekly unattended run with JSON and capped log size:

```bash
sudo LOG_MAX_SIZE_MB=10 JSON_SUMMARY=true ./sysmaint --upgrade --check-zombies --security-audit
```

- Desktop-focused cleanup, report-only caches:

```bash
./sysmaint --dry-run --json-summary --browser-cache-report --color=always
```

## JSON summary hints

The JSON written to `$LOG_DIR/sysmaint_<RUN_ID>.json` includes:
- Repositories status, kernel info, phase timings, disk deltas
- Capabilities, skipped capabilities, system info (os, uptime, mem, disk)
- Autopilot state and reboot recommendation
- Final upgrade telemetry when `--upgrade` is used
- Color mode, log truncation status and sizes
- Zombie check results, security audit results, browser cache metrics

## Notes

- Dry-run is designed to be safe; prefer testing with `--dry-run` and `JSON_SUMMARY=true` on first run.
- The script avoids aggressive user data purges and only touches caches when explicitly requested.
- For unattended operation, consider passwordless sudo for this script and the `--auto` flag.
