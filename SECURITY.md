# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 2.0.x   | ✅ Active support  |
| 1.0.x   | ⚠️ Security fixes only |
| < 1.0   | ❌ End of life     |

## Reporting a Vulnerability

**Do NOT open a public issue for security vulnerabilities.**

### How to Report

1. **Email**: Send details to [security@harery.com](mailto:security@harery.com)
2. **GitHub**: Use the private [Security Advisories](https://github.com/Harery/OCTALUM-PULSE/security/advisories/new) feature

### What to Include

- Description of the vulnerability
- Steps to reproduce
- Affected versions
- Potential impact
- Suggested fix (if available)

### Response Timeline

| Stage | Target |
|-------|--------|
| Initial Response | 24 hours |
| Triage | 48 hours |
| Fix Development | 7 days (critical), 14 days (high) |
| Patch Release | 24-48 hours after fix |

### Disclosure Policy

- We follow **Coordinated Vulnerability Disclosure**
- Please allow us time to fix before public disclosure
- Credit will be given in release notes (if desired)

## Security Features

OCTALUM-PULSE includes the following security features:

### Built-in Security

- **Input Validation**: All inputs are sanitized
- **Least Privilege**: Minimal sudo requirements
- **Audit Logging**: JSON output for compliance
- **No External Calls**: Zero network dependencies by default
- **Dry-Run Mode**: Safe testing without changes

### Security Scanning

We use automated security scanning:

- **Gosec**: Go security scanner
- **Trivy**: Container vulnerability scanner
- **Dependabot**: Dependency updates
- **CodeQL**: GitHub code analysis

### Secure Installation

```bash
curl -sSL pulse.harery.com/install | bash
```

This script:
- Downloads only from GitHub releases
- Verifies binary checksums
- Uses HTTPS only

## Security Best Practices

### Configuration

```yaml
plugins:
  security:
    enabled: true
    standards: [cis]
    cve_scan: true
```

### Running Safely

```bash
pulse doctor              # Safe health check
pulse update --dry-run    # Preview changes
pulse security audit      # Security audit
```

### Sudo Requirements

PULSE requires root for:
- Package installation/removal
- System configuration changes
- Service management

Run with least privilege:
```bash
pulse doctor    # No sudo needed
sudo pulse fix  # Sudo only when required
```

## Security Contacts

| Role | Contact |
|------|---------|
| Security Team | security@harery.com |
| Maintainer | @Harery |

## Acknowledgments

We thank all security researchers who responsibly disclose vulnerabilities.

### Hall of Fame

(No disclosures yet - be the first!)

---

**Last Updated**: 2026-03-15
