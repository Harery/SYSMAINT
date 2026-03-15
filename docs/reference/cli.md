# CLI Reference

Complete command-line interface reference for OCTALUM-PULSE.

## Global Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--config` | `-c` | Config file path |
| `--dry-run` | `-d` | Preview changes without executing |
| `--json` | | Output in JSON format |
| `--log-level` | `-l` | Log level (debug, info, warn, error) |
| `--quiet` | `-q` | Suppress non-essential output |
| `--verbose` | `-v` | Enable verbose output |
| `--version` | | Print version information |
| `--help` | `-h` | Show help |

## Commands

### doctor

Run a comprehensive system health check.

```bash
pulse doctor [flags]

Flags:
  --quick     Quick check (essential items only)
  --full      Full diagnostic (all checks)
  --fix       Attempt to fix issues found
```

### fix

Fix detected system issues.

```bash
pulse fix [flags]

Flags:
  --auto, -a     Automatically fix without prompting
  --category    Fix specific category (packages, security, performance)
```

### update

Update system packages.

```bash
pulse update [flags]

Flags:
  --security-only    Only security updates
  --smart            Smart update (safe packages only)
  --hold PACKAGES    Hold specific packages
  --exclude PACKAGES Exclude specific packages
```

### cleanup

Clean up system (logs, cache, temp files).

```bash
pulse cleanup [flags]

Flags:
  --all              Clean everything
  --logs             Clean logs only
  --cache            Clean package cache only
  --temp             Clean temp files only
  --kernels          Remove old kernels
  --threshold N      Free space threshold (GB)
```

### security

Security-related commands.

```bash
pulse security audit     Run security audit
pulse security scan      Scan for CVEs
pulse security harden    Apply security hardening

Flags:
  --standard NAME    Check against standard (cis, stig)
  --fix              Apply fixes where possible
```

### compliance

Compliance checking and reporting.

```bash
pulse compliance check --standard NAME

Standards:
  hipaa     HIPAA compliance
  soc2      SOC 2 Type II
  pci-dss   PCI DSS
  cis       CIS Benchmarks
  gdpr      GDPR (data handling)
```

### explain

AI-powered explanation of recent changes.

```bash
pulse explain [flags]

Flags:
  --last N    Explain last N operations (default: 5)
  --detail    Include detailed analysis
```

### history

View operation history.

```bash
pulse history [flags]

Flags:
  --last N       Show last N operations
  --json         Output as JSON
  --reverse      Show newest first
```

### rollback

Rollback to previous state.

```bash
pulse rollback [flags]

Flags:
  --last          Rollback last operation
  --id ID          Rollback to specific snapshot ID
  --list           List available snapshots
```

### tui

Launch interactive terminal UI.

```bash
pulse tui
```

### plugin

Plugin management.

```bash
pulse plugin list                    List installed plugins
pulse plugin install URL             Install plugin
pulse plugin update NAME             Update plugin
pulse plugin remove NAME             Remove plugin
pulse plugin init NAME               Create new plugin scaffold
```

### version

Print version information.

```bash
pulse version

Output:
  OCTALUM-PULSE v2.0.0
  Build: 2026-03-15_12:00:00
  Commit: abc1234
  Go: go1.22.0
  Platform: linux/amd64
```

## Exit Codes

| Code | Name | Description |
|------|------|-------------|
| 0 | SUCCESS | Operation completed successfully |
| 1 | GENERAL_ERROR | Unspecified error |
| 2 | LOCK_EXISTS | Another instance is running |
| 3 | UNSUPPORTED_DISTRO | Distribution not supported |
| 4 | PERMISSION_DENIED | Insufficient privileges |
| 5 | PACKAGE_MANAGER_ERROR | Package operation failed |
| 10 | REPO_ISSUES | Repository problems |
| 20 | MISSING_KEYS | GPG keys missing |
| 30 | FAILED_SERVICES | Services failed |
| 75 | LOCK_TIMEOUT | Could not acquire lock |
| 100 | REBOOT_REQUIRED | System reboot required |

## Environment Variables

| Variable | Description |
|----------|-------------|
| `PULSE_CONFIG_DIR` | Override config directory |
| `PULSE_DATA_DIR` | Override data directory |
| `PULSE_LOG_DIR` | Override log directory |
| `PULSE_CACHE_DIR` | Override cache directory |
| `PULSE_SKIP_SUDO` | Skip sudo elevation (dangerous) |
| `PULSE_AUTO_MODE` | Enable non-interactive mode |
