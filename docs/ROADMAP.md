# sysmaint Roadmap & Licensing Notes

> Copyright (c) 2025 Mohamed Elharery <Mohamed@Harery.com>

## Project License
**sysmaint is released under the MIT License** (see LICENSE file in repository root).

This ensures:
- ✅ Open source distribution and modification
- ✅ Commercial use permitted
- ✅ Attribution required
- ✅ No warranty or liability
- ✅ Compatible with most permissive licenses (Apache-2.0, BSD, GPL)

## Licensing Due Diligence & Clean-Room Status
The original external snap cleanup reference script was used **only as conceptual inspiration** (patterns: old revision enumeration, cache clearing). **No direct code has been copied into sysmaint.** All implementations are clean-room rewrites to ensure license independence and IP safety.

**Status: RESOLVED — Clean-room implementation maintained.**

Action Items (completed):
1. ✅ Confirmed no direct code copying from external references
2. ✅ All snap cleanup logic independently implemented
3. ✅ No proprietary or unlicensed code dependencies
4. ✅ Clean attribution maintained in code comments where applicable

**Decision:** Continue clean-room status indefinitely; no external code import needed or planned.

## Completed High-Priority Features (v2.1.1)

### Core Maintenance (v2.0.0)
- Kernel/orphan purge + post-kernel finalize (update-initramfs, updatedb, optional update-grub)
- Capability & mode detection with desktop guard
- Adaptive timing (EMA) with host profiling (CPU/RAM/NET scaling)
- Snap maintenance trio: refresh, old revision cleanup, cache clear
- Crash dump purge, fstrim, drop caches with memory/swap metrics
- Thumbnail & journal retention phases
- Firmware, DNS cache, failed services checks
- Enhanced JSON telemetry: timings, disk deltas, capabilities, system info
- Stale lock auto-clean logic with PID tracking
- Autopilot mode & reboot recommendation fields
- Network retry logic with exponential backoff

### Production Features (v2.1.0)
- ✅ Optional final upgrade phase (`--upgrade`) with JSON metrics
- ✅ Log truncation safety (`--log-max-size-mb`, `--log-tail-keep-kb`)
- ✅ Zombie process detection (`--check-zombies`)
- ✅ Colorized output control (`--color auto|always|never`)
- ✅ Desktop browser cache phase (`--browser-cache-report`, `--browser-cache-purge`)
- ✅ Security hardening audit (`--security-audit`)

### Quality & Testing (v2.1.1)
- ✅ Non-root dry-run without elevation attempts
- ✅ Comprehensive test suite (40+ cases): smoke, full-cycle, edge, schema validation
- ✅ CI integration with matrix and full-cycle jobs
- ✅ Complete documentation: README, tests/README, man page, quick reference
- ✅ Parallel execution mode (experimental: `--parallel`)
- ✅ PHASE_DISK_DELTAS unbound variable fix for parallel mode

### Quality & Testing (v2.1.1)
- ✅ Non-root dry-run without elevation attempts
- ✅ Comprehensive test suite (40+ cases): smoke, full-cycle, edge, schema validation
- ✅ CI integration with matrix and full-cycle jobs
- ✅ Complete documentation: README, tests/README, man page, quick reference
- ✅ Parallel execution mode (experimental: `--parallel`)
- ✅ PHASE_DISK_DELTAS unbound variable fix for parallel mode

## Current Focus & Stabilization (v2.2.0 candidate)

### In Progress
- 🔄 Parallel mode stabilization and production hardening
- 🔄 Extended test coverage for edge cases and stress scenarios
- 🔄 Performance benchmarking and optimization

### Under Consideration
- Configuration file support (`/etc/sysmaint/sysmaint.conf`)
- Notification system (webhook/email on completion or errors)
- Enhanced security audit (additional checks, configurable severity)
- Debian package repository hosting

## Future Work (v2.3.0+)

### Planned Features
1. **Configuration File** (`/etc/sysmaint/sysmaint.conf`)
   - Override defaults without environment variables
   - Per-phase enable/disable toggles
   - Profile support (minimal, standard, aggressive)

2. **Notification System**
   - Webhook on completion (success/failure)
   - Email summary (SMTP or sendmail)
   - Desktop notification integration (notify-send)
   - JSON webhook payload with full telemetry

3. **Snapshot/Rollback Integration**
   - Pre-maintenance snapshot (LVM, Btrfs, ZFS)
   - Automatic rollback on critical failures
   - Snapshot retention policies

4. **Smart Retry Classification**
   - Classify failures (transient vs permanent)
   - Jitter in retry delays to avoid thundering herd
   - Configurable retry strategies per operation type

5. **Enhanced Locking**
   - Distributed lock support (Redis, etcd)
   - Lock priority and preemption
   - Automatic stale lock cleanup by configurable age

6. **Extended Diagnostics**
   - Package manager health checks
   - Dependency graph analysis
   - Predictive maintenance recommendations
   - System resource trending

### Research & Exploration
- Integration with configuration management (Ansible, Salt, Puppet)
- Cloud provider metadata integration (AWS, Azure, GCP)
- Container/VM-aware maintenance strategies
- A/B testing framework for maintenance strategies

## Postponed / Deferred

### Explicitly Deferred
❌ **Aggressive user data purges** — Intentionally avoided; only caches touched when explicitly requested  
❌ **Dev tool cache wipes** — Risk of breaking workflows; users can script separately  
❌ **Automatic package pinning/holding** — Too opinionated; users should manage via apt preferences  
❌ **Custom kernel compilation** — Out of scope; distro kernels only  
❌ **Third-party PPA management** — Too risky; users handle manually

### On Hold Pending Dependencies
⏸️ **GUI frontend** — Waiting for stable API and use case validation  
⏸️ **Multi-distro support** — Focus on Ubuntu/Debian first; Fedora/Arch later  
⏸️ **Windows/macOS ports** — Linux-only for now

## Design Principles
- **Idempotent phases:** Each phase safe to run multiple times
- **Dry-run fidelity:** Simulate side-effects and produce realistic estimates
- **Strict mode:** `set -Eeuo pipefail` with controlled error suppression
- **Minimal dependencies:** Primarily POSIX + coreutils + apt
- **Conservative defaults:** Opt-in for destructive operations
- **Rich telemetry:** JSON schema with comprehensive metrics
- **Exit code semantics:** Distinct codes for different failure modes

## Contributing & Development

### How to Contribute
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make changes with tests (`bash tests/dryrun_fullcycle.sh`)
4. Update documentation (README, man page, CHANGELOG)
5. Commit with descriptive messages
6. Push and open a pull request

### Development Setup
```bash
# Clone and test
git clone <repo-url>
cd sysmaint
bash tests/smoke.sh
bash tests/args_edge.sh
bash tests/dryrun_fullcycle.sh

# Install for local testing
sudo install -Dm755 sysmaint /usr/local/sbin/sysmaint
```

### Coding Standards
- Bash strict mode required
- shellcheck clean (SC2221/SC2222 warnings acceptable for large case statements)
- Functions documented with purpose and parameters
- Exit codes mapped to semantic meanings
- JSON schema backward-compatible changes only

## Version History & Milestones

- **v2.1.1** (2025-11-12) — Dry-run elevation fix, full-cycle test suite, documentation complete
- **v2.1.0** (2025-11-10) — Production features: upgrade, color, logs, zombies, security, browser
- **v2.0.0** (2025-11-09) — Network retry, enhanced locking, health checks, mirror diagnostics
- **v1.x** — Baseline APT maintenance with JSON telemetry

## Notes
`sysmaint` intentionally avoids aggressive user data purges and dev tool cache wipes unless explicitly reintroduced under future guarded flags.

---
Last updated: 2025-11-12
