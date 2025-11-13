# sysmaint (v2.1.1)

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

### Quick smoke test

Run a fast baseline dry-run:

```bash
bash tests/smoke.sh
```

This runs the script with several argument combinations and validates JSON output.

### Full-cycle test suite

Run the comprehensive dry-run suite covering all flags progressively (default → fixed combos → optional → broad combined):

```bash
bash tests/dryrun_fullcycle.sh
```

This suite tests:
- Default run (no flags)
- Fixed combos: `--upgrade`, `--simulate-upgrade`, color/audit/zombies, browser cache report
- Optional toggles: fstrim, drop-caches, kernel purge, orphan purge, snap/flatpak options, disable flags, progress modes, lock settings, log truncation, parallel exec
- Autopilot variants: `--auto`, custom reboot delays
- Broad combined: most optional features together
- Negative sweep: disabling most defaults

Each case validates the resulting JSON against the schema. Runs are non-destructive (DRY_RUN=true throughout).

### Edge-case argument tests

Verify argument parsing and non-root + dry-run combinations:

```bash
bash tests/args_edge.sh
```

### JSON schema validation

Validate a specific JSON summary against the schema:

```bash
bash tests/validate_json.sh
# Or manually:
python3 tests/validate_json.py docs/schema/sysmaint-summary.schema.json /tmp/system-maintenance/sysmaint_<RUN_ID>.json
```

All tests run automatically in CI via `.github/workflows/dry-run.yml`.
