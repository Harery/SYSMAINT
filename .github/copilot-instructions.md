# Sysmaint — AI Agent Development Guide

Multi-distro Linux system maintenance toolkit. Bash 5.x, modular architecture.

---

## Architecture

```
sysmaint                    # Entry point
lib/
├── core/                   # init, logging, detection, errors
├── maintenance/            # packages, kernel, snap, flatpak, storage
├── os_families/            # debian, redhat, arch, suse overrides
├── progress/               # UI, ETA, parallel execution
├── reporting/              # JSON telemetry
├── gui/                    # TUI (dialog/whiptail)
└── validation/             # security audits
```

OS family libraries load dynamically via `lib/core/init.sh` based on `/etc/os-release`.

---

## Non-Negotiable Contracts

### Naming Conventions
| Type | Pattern | Example |
|------|---------|---------|
| Public functions | `snake_case` | `pkg_upgrade`, `detect_package_manager` |
| Private functions | `_underscore_prefix` | `_skip_cap`, `_ema_update` |
| OS family functions | `{family}_*` | `debian_kernel_pattern` |
| Detection variables | `DETECTED_*` | `DETECTED_OS_ID`, `DETECTED_PKG_MANAGER` |

### Logging (lib/core/logging.sh)
```bash
log "=== Phase description ==="     # Section headers
run apt-get update                   # Command execution with logging
```

### Dry-Run Safety (Mandatory)
```bash
if [[ "${DRY_RUN:-false}" == "true" ]]; then
  log "DRY_RUN: would run: $cmd"
  return 0
fi
```

### Package Manager Abstraction (lib/package_manager.sh)
Never call package managers directly. Use:
- `pkg_update()`, `pkg_upgrade()`, `pkg_full_upgrade()`, `pkg_autoremove()`

### Exit Codes (Immutable)
| Code | Meaning |
|------|---------|
| 0 | Success |
| 10 | Repository validation failures |
| 20 | Missing APT public keys |
| 30 | Failed systemd services |
| 75 | Lock acquisition timeout |
| 100 | Reboot required |

---

## Testing

```bash
# Quick validation
bash tests/test_suite_smoke.sh

# Full suite
for s in smoke edge security compliance governance performance scanners combos; do
  bash tests/test_suite_${s}.sh
done
```

- All tests use `DRY_RUN=true` — no system changes
- Mocks in `tests/mocks/realmodesandbox/bin/` via `_shim`
- JSON validation: `python3 tests/validate_json.py docs/schema/sysmaint-summary.schema.json`

---

## Adding Features

### New Module
1. Create `lib/maintenance/feature.sh`
2. Source in `sysmaint` (lines 100-140)
3. Add capability check in `lib/core/capabilities.sh`
4. Add CLI flag parsing
5. Add tests in `tests/test_suite_*.sh`

### OS Family Code
```bash
# lib/os_families/{family}_family.sh
debian_family_init() {
  # Override generic functions
}
```

---

## CI Requirements

- **ShellCheck**: `-x -S error`
- **Platforms**: Ubuntu, Debian, Fedora, CentOS, RHEL, Rocky, Alma, Arch, openSUSE

---

## JSON Telemetry

Output: `/tmp/system-maintenance/sysmaint_*.json`  
Schema: `docs/schema/sysmaint-summary.schema.json`

```json
{
  "exit_code": 0,
  "reboot_required": false,
  "disk_usage": {"before_kb": 0, "after_kb": 0, "saved_kb": 0}
}
```

---

## Behavior Guarantees

- **Dry-run mode**: No destructive actions when `--dry-run` enabled
- **Logging**: All operations logged with timestamps
- **Detection outputs**: `DETECTED_*` variables are authoritative
- **OS consistency**: Same behavior across supported platforms
