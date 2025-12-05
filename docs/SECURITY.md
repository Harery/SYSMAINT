# Security Hardening Guide

Name: Security Hardening
Purpose: Enable and interpret audit; best practices and integrations
Need: Operational security posture and compliance readiness
Function: Explain checks, outputs, remediation, and tool integrations

> © 2025 Mohamed Elharery <Mohamed@Harery.com> • [www.harery.com](https://www.harery.com)

**Version**: 2.1.2  
**Last Updated**: November 30, 2025

[![Release](https://img.shields.io/github/v/release/Harery/SYSMAINT?label=release&color=green)](https://github.com/Harery/SYSMAINT/releases/latest)

---

## Table of Contents

1. [Overview](#overview)
2. [Security Audit Feature](#security-audit-feature)
3. [File Permission Checks](#file-permission-checks)
4. [Understanding Security Warnings](#understanding-security-warnings)
5. [Best Practices](#best-practices)
6. [Integration with External Tools](#integration-with-external-tools)

---

## Overview

`sysmaint` includes a built-in security audit framework that validates critical system file permissions and configurations. This feature is optional and can be enabled per-run or configured permanently.

### When to Use Security Audit

- **Production systems**: Regular validation of security-sensitive configurations
- **Compliance requirements**: Automated checks for security baselines
- **Post-maintenance verification**: Ensure maintenance didn't alter critical permissions
- **Security hardening**: Integrate with broader security frameworks

---

## Security Audit Feature

### Enabling Security Audit

**Command-line flag**:
```bash
sudo ./sysmaint --dry-run --security-audit
```

**Environment variable**:
```bash
SECURITY_AUDIT_ENABLED=true sudo ./sysmaint --dry-run
```

**Permanent configuration** (for systemd timer):
```bash
# Edit /etc/systemd/system/sysmaint.service
Environment="SECURITY_AUDIT_ENABLED=true"
```

### What Gets Checked

The security audit validates permissions on:

1. **Password files**:
   - `/etc/shadow` - Encrypted passwords (should be `root:root 600`)
   - `/etc/gshadow` - Group passwords (should be `root:root 600`)

2. **Privilege escalation**:
   - `/etc/sudoers` - Sudo configuration (should be `root:root 440` or `400`)
   - `/etc/sudoers.d/*` - Sudo drop-in files (should be `root:root 440` or `400`)

### Output Format

**Console output**:
```
=== Security audit start ===
Security audit results: shadow_ok=true gshadow_ok=true sudoers_ok=true sudoers.d_issues=0
=== Security audit complete ===
```

**JSON output** (when `JSON_SUMMARY=true`):
```json
{
  "security_audit_enabled": true,
  "shadow_perms_ok": "true",
  "gshadow_perms_ok": "true",
  "sudoers_perms_ok": "true",
  "sudoers_d_issues": []
}
```

---

## File Permission Checks

### Shadow File (`/etc/shadow`)

**Expected configuration**:
- Owner: `root`
- Group: `root` (or `shadow` on some systems)
- Permissions: `600` (read/write for owner only)

**Why it matters**: Contains encrypted password hashes. If readable by non-root users, attackers can attempt offline password cracking.

**Common issues**:
- Permissions `640` with group `shadow`: This is **by design** on many systems to allow certain authentication tools to read hashes. Not a security issue if the `shadow` group membership is properly controlled.
- Permissions `644`: **CRITICAL** - passwords readable by all users.

### GShadow File (`/etc/gshadow`)

**Expected configuration**:
- Owner: `root`
- Group: `root` (or `shadow`)
- Permissions: `600`

**Why it matters**: Contains group password hashes and group administrator information.

**Common issues**: Similar to `/etc/shadow` - `640` with group `shadow` is often intentional.

### Sudoers File (`/etc/sudoers`)

**Expected configuration**:
- Owner: `root`
- Group: `root`
- Permissions: `440` or `400`

**Why it matters**: Controls which users can execute commands as root. Incorrect permissions could allow unauthorized privilege escalation.

**Common issues**:
- Permissions `644`: **CRITICAL** - allows any user to read or modify sudo rules.
- Missing file: System misconfiguration.

### Sudoers Drop-in Files (`/etc/sudoers.d/*`)

**Expected configuration**: Same as `/etc/sudoers`

**Why it matters**: These files are included by `/etc/sudoers` and have equal privilege escalation impact.

**Common issues**:
- World-writable files: **CRITICAL** - any user can grant themselves root access.
- Backup files (`.bak`, `~`): Often left behind by editors and can have incorrect permissions.

---

## Understanding Security Warnings

### When Shadow/GShadow Show as "false"

If you see:
```
Security audit results: shadow_ok=false gshadow_ok=false sudoers_ok=true
```

**This is often NOT a security problem**. Many distributions intentionally set:
```bash
$ ls -l /etc/shadow /etc/gshadow
-rw-r----- 1 root shadow 1234 Nov 15 10:00 /etc/shadow
-rw-r----- 1 root shadow 567  Nov 15 10:00 /etc/gshadow
```

**Explanation**:
- Permissions `640` (owner read/write, group read, others none)
- Group `shadow` allows specific system services (PAM, systemd-logind) to authenticate users
- Only root can add users to the `shadow` group
- This is the **default configuration** on Ubuntu, Debian, and many other distros

**Action required**: None, unless you've manually added untrusted users to the `shadow` group.

### When Warnings ARE Serious

You should investigate immediately if:

1. **Permissions are world-readable**:
   ```
   -rw-r--r-- 1 root root 1234 Nov 15 10:00 /etc/shadow
   ```
   ❌ **CRITICAL**: Any user can read password hashes.

2. **Owner is not root**:
   ```
   -rw------- 1 www-data root 1234 Nov 15 10:00 /etc/shadow
   ```
   ❌ **CRITICAL**: Non-root user owns password file.

3. **Sudoers files are writable**:
   ```
   -rw-rw-r-- 1 root root 456 Nov 15 10:00 /etc/sudoers
   ```
   ❌ **CRITICAL**: Group or others can modify sudo rules.

### How to Fix Permission Issues

**For shadow/gshadow**:
```bash
# Secure (restrictive) configuration
sudo chown root:root /etc/shadow /etc/gshadow
sudo chmod 600 /etc/shadow /etc/gshadow

# OR standard (system authentication) configuration
sudo chown root:shadow /etc/shadow /etc/gshadow
sudo chmod 640 /etc/shadow /etc/gshadow
```

**For sudoers**:
```bash
sudo chown root:root /etc/sudoers
sudo chmod 440 /etc/sudoers

# Fix all sudoers.d files
sudo chown root:root /etc/sudoers.d/*
sudo chmod 440 /etc/sudoers.d/*

# Remove backup files
sudo rm -f /etc/sudoers.d/*.bak /etc/sudoers.d/*~
```

---

## Best Practices

### 1. Run Security Audit Regularly

**Weekly via systemd timer**:
```bash
# Add to sysmaint.service
Environment="SECURITY_AUDIT_ENABLED=true"
```

**Manual validation after changes**:
```bash
sudo ./sysmaint --dry-run --security-audit
```

### 2. Monitor JSON Output

Integrate with monitoring systems:

```bash
# Extract security status
jq '.shadow_perms_ok, .gshadow_perms_ok, .sudoers_perms_ok' \
   /tmp/system-maintenance/sysmaint_*.json

# Alert on failures
if jq -e '.sudoers_perms_ok == "false"' sysmaint.json; then
  echo "ALERT: Sudoers permission issue detected" | mail -s "Security Alert" admin@example.com
fi
```

### 3. Understand Your Distribution's Defaults

Before "fixing" warnings, verify your distribution's expected configuration:

```bash
# Check shadow group usage
getent group shadow

# See which processes use shadow
sudo lsof /etc/shadow /etc/gshadow
```

### 4. Combine with External Tools

**Lynis integration**:
```bash
# Run sysmaint security audit
sudo ./sysmaint --dry-run --security-audit

# Then run comprehensive system scan
sudo lynis audit system
```

**rkhunter integration**:
```bash
# Check for rootkits
sudo rkhunter --check --skip-keypress

# Then run sysmaint with security audit
sudo ./sysmaint --security-audit
```

### 5. Document Exceptions

If your system intentionally deviates from the expected configuration:

```bash
# Create /etc/sysmaint.conf
cat > /etc/sysmaint.conf <<'EOF'
# shadow/gshadow use group 'shadow' for PAM authentication (expected)
SHADOW_GROUP_ALLOWED=true

# Custom sudoers configuration reviewed 2025-11-15
SUDOERS_CUSTOM_REVIEWED=true
EOF
```

---

## Integration with External Tools

### Ansible/Puppet/Chef

```yaml
# Ansible playbook example
- name: Run sysmaint with security audit
  command: /usr/local/bin/sysmaint --dry-run --security-audit
  register: sysmaint_result

- name: Parse security audit results
  set_fact:
    security_status: "{{ sysmaint_result.stdout | from_json }}"

- name: Alert on security issues
  mail:
    subject: "Security audit failed on {{ inventory_hostname }}"
    body: "{{ security_status }}"
  when: security_status.sudoers_perms_ok == "false"
```

### Prometheus/Grafana

Export sysmaint JSON to metrics:

```python
#!/usr/bin/env python3
# sysmaint_exporter.py
import json
from prometheus_client import Gauge, CollectorRegistry, write_to_textfile

registry = CollectorRegistry()
shadow_ok = Gauge('sysmaint_shadow_perms_ok', 'Shadow file permissions OK', registry=registry)
gshadow_ok = Gauge('sysmaint_gshadow_perms_ok', 'GShadow file permissions OK', registry=registry)
sudoers_ok = Gauge('sysmaint_sudoers_perms_ok', 'Sudoers file permissions OK', registry=registry)

with open('/tmp/system-maintenance/sysmaint_latest.json') as f:
    data = json.load(f)

shadow_ok.set(1 if data['shadow_perms_ok'] == 'true' else 0)
gshadow_ok.set(1 if data['gshadow_perms_ok'] == 'true' else 0)
sudoers_ok.set(1 if data['sudoers_perms_ok'] == 'true' else 0)

write_to_textfile('/var/lib/node_exporter/sysmaint.prom', registry)
```

### SIEM Integration

```bash
# Send sysmaint JSON to syslog
logger -t sysmaint -p local0.info -f /tmp/system-maintenance/sysmaint_*.json

# Splunk forwarder will pick up from /var/log/syslog
```

---

## Summary

- **Security audit is optional** - enable with `--security-audit` or `SECURITY_AUDIT_ENABLED=true`
- **Shadow/gshadow warnings are often expected** - verify your distribution's defaults before "fixing"
- **Sudoers issues are always serious** - investigate immediately
- **Integrate with existing tools** - lynis, rkhunter, monitoring systems
- **Use JSON output for automation** - parse results for alerting and compliance reporting

---

<div align="center">

**[← Back to README](../README.md)** • **[Features](../FEATURES.md)** • **[Releases Roadmap](../RELEASES.md)**

**MIT Licensed** • **[www.harery.com](https://www.harery.com)**

</div>
