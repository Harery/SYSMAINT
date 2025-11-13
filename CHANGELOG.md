# Changelog

> Copyright (c) 2025 Mohamed Elharery <Mohamed@Harery.com>

## 2.1.1 — 2025-11-12

Added
- Comprehensive full-cycle test suite (40+ cases) covering all flags progressively
- tests/README.md with complete test documentation
- CI integration: full-cycle job in dry-run workflow
- Testing section in main README

Fixed
- PHASE_DISK_DELTAS unbound variable error in parallel mode (set -u guards)

## 2.1.0 — 2025-11-10

Added
- Optional final upgrade phase (`--upgrade`) with JSON: `final_upgrade_enabled`, `final_upgrade_*_count`.
- Color control (`--color auto|always|never`); JSON includes `color_mode`.
- Log truncation safeguards (`LOG_MAX_SIZE_MB`, `LOG_TAIL_PRESERVE_KB`); JSON: `log_truncated`, sizes.
- Zombie process detection (`--check-zombies`), JSON: `zombie_count`, `zombie_processes`.
- Minimal security audit (`--security-audit`), JSON with `shadow_perms_ok`, `gshadow_perms_ok`, `sudoers_perms_ok`, `sudoers_d_issues`.
- Browser cache phase (`--browser-cache-report` / `--browser-cache-purge`), JSON cache sizes and `browser_cache_purged`.
- Extended JSON telemetry ordering to include diagnostics before summary.

Improved
- CLI parsing (getopt + fallback) gained `--upgrade`, new flags.
- Usage documentation now includes new flags and environment variables.
 - Documentation expanded: README "Behavior overview" (defaults/fixed/optional/args) and updated docs/quick_reference.txt to v2.1.0.

Fixed
- Stale lock handling and sequencing had stability improvements in prior cycle (2.0.x); retained.

## 2.0.0
- Baseline release referenced in this repo (not exhaustively documented here).
