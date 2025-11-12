# sysmaint Roadmap & Licensing Notes

## Licensing Due Diligence
The original external snap cleanup reference script was only used conceptually (patterns: old revision enumeration, cache clearing). No direct code has been copied into `sysmaint`. Until an explicit license for that reference is confirmed, treat all external content as inspiration only. If a permissive license (MIT/BSD/Apache-2.0) is later identified, targeted code import can be reconsidered; otherwise maintain clean-room reimplementation status.

Action Items:
1. Identify source repository or distribution channel of the reference script.
2. Retrieve LICENSE file or headers.
3. If no license: continue treating as proprietary reference; do not copy code.
4. Document outcome here once known.

## Completed High-Priority Features
- Kernel/orphan purge + post-kernel finalize (update-initramfs, updatedb, optional update-grub)
- Capability & mode detection with desktop guard.
- Adaptive timing (EMA) with host profiling (CPU/RAM/NET scaling).
- Snap maintenance trio: refresh, old revision cleanup, cache clear.
- Crash dump purge, fstrim, drop caches with memory/swap metrics.
- Thumbnail & journal retention phases.
- Firmware, DNS cache, failed services checks.
- Enhanced JSON telemetry: timings, disk deltas, capabilities, skipped_capabilities, system info, autopilot settings.
- Stale lock auto-clean logic.
- Autopilot mode & reboot recommendation fields.

## Upcoming (Prioritized)
1. License compatibility verification (see above).
2. Optional upgrade phase (`--upgrade`) final pass apt full-upgrade, JSON metrics.
3. Log truncation safety (threshold + rotation with delta accounting).
4. Zombie process detection (dry-run informational).
5. Colorized output flag (`--color auto|never|always`).
6. Desktop browser cache phase (size & optional purge).
7. Security hardening audit (permissions reporting only by default).

## Design Principles
- Idempotent phases: each phase safe to run multiple times.
- Dry-run fidelity: simulate side-effects and produce realistic estimates.
- Strict mode with controlled error suppression.
- Minimal external dependencies (primarily POSIX + coreutils + apt).

## Notes
`sysmaint` intentionally avoids aggressive user data purges and dev tool cache wipes unless explicitly reintroduced under future guarded flags.

---
Last updated: $(date -Iseconds)
