# sysmaint (v2.1.1)

> Copyright (c) 2025 Mohamed Elharery <Mohamed@Harery.com>

A safe, scriptable Ubuntu/Debian maintenance runner: APT + Snap updates, cleanup phases, rich JSON telemetry, and unattended/autopilot mode.

**License**: MIT | **Status**: Production Ready | **Tests**: 290+ scenarios (100% pass)

## Documentation

- **Complete Documentation**: See [DOCUMENTATION.md](DOCUMENTATION.md) for comprehensive guide
  - Project overview and status
  - Development roadmap (Stage 1 ✅ Complete, Stage 2 🚧 Planned)
  - Complete changelog
  - Testing & validation results (290+ scenarios)
  - Audit & governance report (Grade A+)
- **Quick Reference**: See below for common commands and flags
- **Man Page**: `man sysmaint` (after installation)

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

## Tier 1 profile launcher (Stage 2)

Use `./sysmaint_profiles.sh` for guided presets that bundle the most common flows. Each profile previews the command, highlights risk/time estimates, and requests confirmation before running unless `--yes` is supplied.

| Key | Profile | Purpose | Command Highlights | Est. Time | Risk |
|-----|---------|---------|--------------------|-----------|------|
| `minimal` | Minimal Preview | Safest telemetry-only dry-run | `--dry-run --json-summary` | ~2 min | None |
| `standard` | Standard Autopilot | Weekly unattended maintenance | `--auto --json-summary --auto-reboot-delay 45` | ~5 min | Low |
| `desktop` | Desktop Cleanup | Adds browser cache purge + colorful progress | `--browser-cache-report --browser-cache-purge --progress=spinner` | ~6 min | Medium |
| `server` | Server Hardened | Security audit + zombie scan + upgrade | `--upgrade --security-audit --check-zombies --auto` | ~8 min | Medium |
| `aggressive` | Aggressive Cleanup | Max disk reclamation incl. kernel purge | `--upgrade --purge-kernels --keep-kernels=2 --orphan-purge --fstrim --drop-caches` | ~10 min | High |

Example: preview the desktop profile without running it, then launch standard autopilot without prompts.

```bash
# Preview only
./sysmaint_profiles.sh --profile desktop --print-command

# Run standard profile immediately (Tier 1, Stage 2)
./sysmaint_profiles.sh --profile standard --yes
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
- Dry-run indicator: `dry_run_mode` shows whether the run actually mutated the system
- Autopilot state and reboot recommendation
- Final upgrade telemetry when `--upgrade` is used
- Color mode, log truncation status and sizes
- Zombie check results, security audit results, browser cache metrics

## Behavior overview

### Defaults (no flags)

| Area         | Default behavior                                               |
|--------------|----------------------------------------------------------------|
| APT          | update, upgrade, autoremove, autoclean                         |
| Snap/Flatpak | Snap refresh; Flatpak update if installed                      |
| Firmware     | fwupd check if installed                                       |
| Cleanup      | DNS cache, journal (7d/500M), thumbnails, crash dumps          |
| Temp         | Clear /tmp safely by age                                       |
| Diagnostics  | Check failed services and zombie processes                     |

### Fixed (always on)

| Always-on       | Notes                                          |
|-----------------|------------------------------------------------|
| OS family guard | Ubuntu/Debian only                             |
| Lock handling   | Stale detection, bounded retries               |
| Reboot detection| Sets reboot-required in summary/exit code      |
| JSON structure  | Stable schema when JSON is enabled             |

### Optional (opt-in)

| Feature          | Enable with                                           | Notes                                 |
|------------------|-------------------------------------------------------|---------------------------------------|
| Final upgrade    | `--upgrade`                                           | apt full-upgrade near the end         |
| Purge old kernels| `--purge-kernels`                                     | Pair with `--keep-kernels=N` (default 2) |
| Update GRUB      | `--update-grub`                                       | After kernel purge                    |
| Orphan purge     | `--orphan-purge`                                      | Remove orphaned pkgs                  |
| fstrim           | `--fstrim`                                            | SSD TRIM                              |
| Drop caches      | `--drop-caches`                                       | Clears page cache                     |
| Snap cleanup     | `--snap-clean-old`, `--snap-clear-cache`              | Old revisions / cache                 |
| Security audit   | `--security-audit`                                    | shadow/gshadow/sudoers checks         |
| Browser caches   | `--browser-cache-report`, `--browser-cache-purge`     | Report or purge caches                |
| Force /tmp wipe  | `--clear-tmp-force` + `--confirm-clear-tmp-force`     | Aggressive, double-confirm            |

### Argument-controlled (change defaults)

| Setting          | Default        | Change with                                                       |
|------------------|----------------|-------------------------------------------------------------------|
| Auto pilot       | off            | `--auto` (sets -y, enables auto-reboot with delay)                |
| Auto reboot delay| 30s            | `--auto-reboot-delay=<sec>`                                       |
| JSON summary     | off            | `JSON_SUMMARY=true` or `--json-summary`                           |
| Dry run          | off            | `DRY_RUN=true` or `--dry-run`                                     |
| Color mode       | auto           | `--color=auto|always|never`                                       |
| Log cap          | disabled       | `--log-max-size-mb=<MB>`, `--log-tail-keep-kb=<KB>`               |
| Snap             | on             | `--no-snap`                                                       |
| Zombies check    | on             | `--no-check-zombies` to disable                                   |
| DNS cache        | on             | `--no-clear-dns-cache` to disable                                 |
| Journal vacuum   | on (7d/500M)   | `--no-journal-vacuum`, `--journal-days=<N>`                       |
| Crash dumps      | on             | `--no-clear-crash` to disable                                     |
| /tmp cleanup     | on (safe by age)| `--no-clear-tmp`, `--clear-tmp-age=<days>`                        |
| Flatpak          | on if installed| `--no-flatpak` or scope via `--flatpak-user-only|--flatpak-system-only` |
| Firmware         | on if installed| `--no-firmware`                                                   |
| Kernels kept     | 2              | `--keep-kernels=<N>` (with `--purge-kernels`)                      |
| Lock wait        | 3s             | `--lock-wait-seconds=<N>`                                         |
| Desktop guard    | on             | `--no-desktop-guard`                                              |
| Progress UI      | none           | `--progress=none|dots|countdown|bar|spinner|adaptive`             |

## systemd timer example

Provide a weekly unattended run using systemd:

1) Install the script and units

```bash
sudo install -Dm755 sysmaint /usr/local/sbin/sysmaint
sudo install -Dm644 packaging/systemd/sysmaint.service /etc/systemd/system/sysmaint.service
sudo install -Dm644 packaging/systemd/sysmaint.timer /etc/systemd/system/sysmaint.timer
```

2) Enable and start the timer

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now sysmaint.timer
sudo systemctl list-timers | grep sysmaint
```

Optional: Create `/etc/sysmaint/sysmaint.env` to override environment (e.g. `LOG_MAX_SIZE_MB=20`), then uncomment `EnvironmentFile` in the service.

## Notes

- Dry-run is designed to be safe; prefer testing with `--dry-run` and `JSON_SUMMARY=true` on first run.
- The script avoids aggressive user data purges and only touches caches when explicitly requested.
- For unattended operation, consider passwordless sudo for this script and the `--auto` flag.

## Security hardening notes

- Prefer a dedicated sudoers rule to allow non-interactive runs if needed:

	Create `/etc/sudoers.d/sysmaint` with:

	`%sysmaint ALL=(root) NOPASSWD: /usr/local/sbin/sysmaint, /usr/bin/systemctl start sysmaint.service`

	Then add trusted users to the `sysmaint` group.

- Ensure the log directory is root-writable or a secure path:

	- Default `LOG_DIR` is `/tmp/system-maintenance`; override to `/var/log/sysmaint` for servers.
	- Example:

		```bash
		sudo install -d -m 0750 -o root -g adm /var/log/sysmaint
		```

- Validate systemd hardening directives if you customize the service: `ProtectSystem=full`, `NoNewPrivileges=true`, and `PrivateTmp=true` are enabled by default in the provided unit.

## Testing

### Suite 1: Smoke regression (`tests/test_suite_smoke.sh`, 60 tests)

- Combines the former `smoke.sh`, `smoke_extended.sh`, and `smoke_ultra.sh` flows.
- Exercises default, upgrade, color, browser cache, zombie/audit, filesystem, kernel/journal, snap/flatpak, tmp cleanup, desktop guard, and auto/parallel mixes.

```bash
bash tests/test_suite_smoke.sh
```

### Suite 2: Edge parser (`tests/test_suite_edge.sh`, 67 tests)

- Merges `args_edge.sh`, `edge_extended.sh`, and `edge_advanced.sh` into one argument torture suite.
- Covers help/version, non-root + dry-run combos, ordering permutations, duplicate/conflicting flags, expected failures, and stress bundles.

```bash
bash tests/test_suite_edge.sh
```

### Suite 3: Full-cycle lifecycle (`tests/test_suite_fullcycle.sh`, 97 tests)

- Successor to `dryrun_fullcycle.sh`, `fullcycle_advanced.sh`, and the combo gallery.
- Seven phases: defaults, feature toggles, progress/display, advanced ops, combined desktop/server mixes, negative sweeps, and curated feature-combo triples/quads.
- Every case sets `DRY_RUN=true JSON_SUMMARY=true`, validates against the JSON schema, and asserts key fields like `final_upgrade_enabled`, `desktop_guard_enabled`, `auto_mode`, `zombie_check_enabled`, etc.

```bash
bash tests/test_suite_fullcycle.sh
```

### JSON schema validation helpers

```bash
bash tests/validate_json.sh
python3 tests/validate_json.py docs/schema/sysmaint-summary.schema.json /tmp/system-maintenance/sysmaint_<RUN_ID>.json
bash tests/test_json_negative.sh
```

### Sandbox real-mode suite (`tests/test_suite_realmode_sandbox.sh`)

Exercises representative non-dry-run flows with `SYSMAINT_FAKE_ROOT=1` and mocked binaries so CI can ensure "real" executions stay healthy.

```bash
bash tests/test_suite_realmode_sandbox.sh
```

### Tier 1 profile launcher tests (`tests/test_profiles_tier1.sh`)

Confirms each preset in `sysmaint_profiles.sh` emits the expected flags and supports extra arguments.

```bash
bash tests/test_profiles_tier1.sh
```

### Package build validation (`tests/test_package_build.sh`)

Builds the `.deb` in a temp directory and (when `lintian` is installed) lint-checks the artifact.

```bash
bash tests/test_package_build.sh
```

### Run everything

```bash
bash tests/test_suite_smoke.sh && \
bash tests/test_suite_edge.sh  && \
bash tests/test_suite_fullcycle.sh && \
bash tests/validate_json.sh
```

All suites stay in dry-run mode and run automatically in `.github/workflows/dry-run.yml`.

## Quick Reference

### Common Commands

```bash
# Normal run (safe defaults)
sudo ./sysmaint

# Dry-run with JSON summary
DRY_RUN=true JSON_SUMMARY=true ./sysmaint --dry-run --json-summary

# Autopilot with auto-reboot
sudo ./sysmaint --auto --auto-reboot-delay 45 --json-summary

# Optional final upgrade
sudo ./sysmaint --upgrade

# Help
./sysmaint --help | less
```

### Key Flags Summary

**Safety/Flow**:
- `--dry-run`, `--json-summary`, `--auto`, `--auto-reboot-delay=N`
- `--color=auto|always|never`

**Optional Phases**:
- `--upgrade`, `--purge-kernels`, `--keep-kernels=N`, `--update-grub`
- `--orphan-purge`, `--fstrim`, `--drop-caches`
- `--browser-cache-report`, `--browser-cache-purge`
- `--security-audit`, `--check-zombies`

**Disable Defaults**:
- `--no-snap`, `--no-flatpak`, `--no-firmware`
- `--no-check-zombies`, `--no-clear-dns-cache`
- `--no-journal-vacuum`, `--no-clear-crash`, `--no-clear-tmp`

**Configuration**:
- `--journal-days=N`, `--lock-wait-seconds=N`
- `--progress=adaptive|dots|spinner|bar|quiet`
- `--log-max-size-mb=MB`, `--log-tail-keep-kb=KB`

### Default Behaviors

| Feature | Default | Override |
|---------|---------|----------|
| APT updates | ✅ Enabled | N/A (always) |
| Snap refresh | ✅ Enabled | `--no-snap` |
| Journal vacuum | ✅ 7 days | `--journal-days=N` or `--no-journal-vacuum` |
| /tmp cleanup | ✅ By age | `--no-clear-tmp` |
| Zombie check | ✅ Enabled | `--no-check-zombies` |
| Final upgrade | ❌ Disabled | `--upgrade` |
| Kernel purge | ❌ Disabled | `--purge-kernels` |
| Browser cache | ❌ Disabled | `--browser-cache-report/purge` |

### File Locations

```
Logs:   /tmp/system-maintenance/sysmaint_*.log
JSON:   /tmp/system-maintenance/sysmaint_*.json
Schema: docs/schema/sysmaint-summary.schema.json
```

### Troubleshooting

- **Exit 75 (lock)**: Increase `--lock-wait-seconds` or use `--force-unlock` if stale
- **Network issues**: Tune `NETWORK_RETRY_*` environment variables
- **No JSON**: Set `JSON_SUMMARY=true` or pass `--json-summary`
- **Permissions**: Run with `sudo` for actual maintenance (dry-run doesn't require root)

## Version & Contact

**Version**: 2.1.1 (November 14, 2025)  
**Author**: Mohamed Elharery <Mohamed@Harery.com>  
**License**: MIT License (see LICENSE file)  
**Repository**: [GitHub](https://github.com/mohamedharery/sysmaint) _(to be configured)_
