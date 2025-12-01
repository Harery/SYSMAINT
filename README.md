# 🛠️ sysmaint

<div align="center">

![Version](https://img.shields.io/badge/version-2.1.2-blue.svg)
[![CI](https://github.com/Harery/SYSMAINT/actions/workflows/ci.yml/badge.svg)](https://github.com/Harery/SYSMAINT/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/tests-246%20passing-brightgreen)](https://github.com/Harery/SYSMAINT)
[![Coverage](https://img.shields.io/badge/coverage-100%25-brightgreen)](https://github.com/Harery/SYSMAINT)

**A safe, scriptable Ubuntu/Debian maintenance automation toolkit**

*APT + Snap updates • Cleanup phases • JSON telemetry • Unattended mode • Security audits*

[Features](FEATURES.md) • [Changelog](CHANGELOG.md) • [Security](docs/SECURITY.md) • [Performance](docs/PERFORMANCE.md)

</div>

---

## ✨ Highlights

| Feature | Description |
|:--------|:------------|
| 📦 **Package Updates** | APT, Snap, Flatpak — all in one run |
| 🧹 **Smart Cleanup** | Temp files, logs, caches, old kernels |
| 🔐 **Security Audit** | Permission checks, zombie detection |
| 📊 **JSON Telemetry** | Detailed reports for monitoring integration |
| 🤖 **Automation Ready** | Systemd timers, unattended mode |
| ✅ **Production Tested** | 246 tests, 100% coverage |

---

## 🚀 Quick Start

### 👁️ Safe Preview (Recommended First Run)

\`\`\`bash
# See what would happen without making changes
./sysmaint --dry-run --json-summary
\`\`\`

### ⚡ Standard Maintenance

\`\`\`bash
# Weekly maintenance with JSON report
sudo ./sysmaint --json-summary
\`\`\`

### 🤖 Unattended Mode

\`\`\`bash
# Fully automated with controlled reboot
sudo ./sysmaint --auto --auto-reboot-delay 45 --json-summary
\`\`\`

### 🚀 Full Upgrade

\`\`\`bash
# Include distribution upgrade phase
sudo ./sysmaint --upgrade --json-summary
\`\`\`

---

## 🎯 Pre-built Profiles

> One command for common scenarios — no configuration needed!

| Profile | Use Case | Risk | Time |
|:--------|:---------|:----:|:----:|
| 🟢 \`minimal\` | Safe telemetry preview | None | ~2m |
| 🔵 \`standard\` | Weekly unattended maintenance | Low | ~5m |
| 🟡 \`desktop\` | Desktop cleanup with visuals | Medium | ~6m |
| 🟠 \`server\` | Hardened server maintenance | Medium | ~8m |
| 🔴 \`aggressive\` | Maximum space reclamation | High | ~10m |

**Usage:**

\`\`\`bash
# Preview what a profile will do
./sysmaint profiles --profile desktop --print-command

# Run a profile directly
./sysmaint profiles --profile standard --yes
\`\`\`

---

## 📋 Common Flags

### ⬆️ Updates & Upgrades

| Flag | Description |
|:-----|:------------|
| \`--upgrade\` | Perform full distribution upgrade |
| \`--no-snap\` | Skip Snap operations |
| \`--no-flatpak\` | Skip Flatpak operations |
| \`--no-firmware\` | Skip firmware updates |

### 🧹 Cleanup Operations

| Flag | Description |
|:-----|:------------|
| \`--purge-kernels\` | Remove old kernel packages |
| \`--keep-kernels=N\` | Keep N old kernels (default: 2) |
| \`--orphan-purge\` | Remove orphaned packages |
| \`--fstrim\` | Run SSD TRIM |
| \`--drop-caches\` | Clear page cache |
| \`--journal-days=N\` | Keep N days of logs |

### 🔐 Security

| Flag | Description |
|:-----|:------------|
| \`--security-audit\` | Check critical file permissions |
| \`--check-zombies\` | Detect zombie processes |

### 🌐 Browser Cache

| Flag | Description |
|:-----|:------------|
| \`--browser-cache-report\` | Show Firefox/Chrome cache sizes |
| \`--browser-cache-purge\` | Delete browser caches |

### ⚡ Automation

| Flag | Description |
|:-----|:------------|
| \`--dry-run\` | Preview without changes |
| \`--auto\` | Unattended mode (no prompts) |
| \`--auto-reboot\` | Reboot if required |
| \`--auto-reboot-delay=N\` | Wait N seconds before reboot |
| \`--yes\` | Auto-approve prompts |

### 📊 Output

| Flag | Description |
|:-----|:------------|
| \`--json-summary\` | Generate JSON report |
| \`--color=MODE\` | \`auto\`, \`always\`, or \`never\` |
| \`--progress=MODE\` | \`spinner\`, \`dots\`, \`bar\`, \`adaptive\` |

> 💡 **Tip:** Disable any default with \`--no-*\` (e.g., \`--no-clear-tmp\`, \`--no-journal-vacuum\`)

---

## 📊 Exit Codes

| Code | Status | Meaning |
|:----:|:------:|:--------|
| \`0\` | ✅ Success | Completed without issues |
| \`1\` | ❌ Error | General failure (check logs) |
| \`2\` | ❌ Invalid Args | Unknown or incorrect flags |
| \`10\` | ⚠️ Repo Issues | APT repository problems |
| \`20\` | ⚠️ Missing Keys | GPG keys not found |
| \`30\` | ⚠️ Failed Services | Systemd units in failed state |
| \`75\` | 🔒 Lock Timeout | Another instance running |
| \`100\` | 🔄 Reboot Needed | Success, but restart required |

> 💡 Both \`0\` and \`100\` indicate successful completion!

---

## 📄 JSON Telemetry

Enable with \`--json-summary\` to get detailed reports in \`/tmp/system-maintenance/\`:

\`\`\`json
{
  "script_version": "2.1.2",
  "run_id": "2025-11-30_120000_12345",
  "exit_code": 0,
  "phases": { ... },
  "disk_delta": { ... },
  "security_audit": { ... }
}
\`\`\`

**Schema:** \`docs/schema/sysmaint-summary.schema.json\`

---

## ⏰ Systemd Timer (Automated Weekly)

\`\`\`bash
# Install sysmaint
sudo install -Dm755 sysmaint /usr/local/sbin/sysmaint

# Install systemd units
sudo install -Dm644 packaging/systemd/sysmaint.service /etc/systemd/system/
sudo install -Dm644 packaging/systemd/sysmaint.timer /etc/systemd/system/

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable --now sysmaint.timer
\`\`\`

**Optional:** Create \`/etc/sysmaint/sysmaint.env\` for custom settings.

---

## 🔐 Security Scanners

### Built-in Audit

\`\`\`bash
# Check shadow, gshadow, sudoers permissions
sudo ./sysmaint --security-audit
\`\`\`

### External Scanners (Lynis + rkhunter)

\`\`\`bash
# Run with threshold enforcement
LYNIS_MIN_SCORE=80 RKHUNTER_MAX_WARNINGS=5 ./sysmaint scanners
\`\`\`

See [docs/SECURITY.md](docs/SECURITY.md) for details.

---

## 🧪 Quality Assurance

\`\`\`
╔═══════════════════════════════════════════════════════════╗
║                    QUALITY DASHBOARD                       ║
╠═══════════════════════════════════════════════════════════╣
║  ✅ Total Tests          │  246 passing                   ║
║  ✅ Test Suites          │  10 comprehensive suites       ║
║  ✅ Coverage             │  100%                          ║
║  ✅ ShellCheck           │  0 errors, 0 warnings          ║
║  ✅ License              │  MIT (all files)               ║
╚═══════════════════════════════════════════════════════════╝
\`\`\`

**Run tests locally:**

\`\`\`bash
# Quick smoke test
bash tests/test_suite_smoke.sh

# Full test suite
for suite in smoke edge security compliance governance performance; do
  bash tests/test_suite_\${suite}.sh
done
\`\`\`

---

## 📚 Documentation

| Document | Purpose |
|:---------|:--------|
| 📋 [FEATURES.md](FEATURES.md) | Complete capability matrix |
| 📝 [CHANGELOG.md](CHANGELOG.md) | Version history |
| 🔐 [docs/SECURITY.md](docs/SECURITY.md) | Security guidelines |
| ⚡ [docs/PERFORMANCE.md](docs/PERFORMANCE.md) | Benchmarks |

---

## 🔧 Defaults at a Glance

| Area | Default Behavior |
|:-----|:-----------------|
| 📦 APT | Update, upgrade, autoremove, autoclean |
| 📱 Snap/Flatpak | Refresh if installed |
| 📜 Journal | Vacuum to 7 days / 500MB |
| 🗂️ /tmp | Age-based cleanup (1 day+) |
| 🖥️ Desktop Guard | Enabled (protects desktop sessions) |
| 👻 Zombie Check | Enabled |
| 🌐 Browser Cache | Disabled (opt-in) |
| ⬆️ Full Upgrade | Disabled (use \`--upgrade\`) |

---

## 💻 Requirements

- **OS:** Ubuntu 20.04+ or Debian 10+
- **Shell:** Bash 4.0+
- **Privileges:** Root for system changes (dry-run works without)

---

## 🤝 Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch
3. Run tests: \`bash tests/test_suite_smoke.sh\`
4. Submit a pull request

See our [Issue Templates](.github/ISSUE_TEMPLATE/) for bug reports and feature requests.

---

<div align="center">

## 👨‍💻 Author

**Mohamed Elharery**

[![Website](https://img.shields.io/badge/Website-www.harery.com-blue?style=flat-square)](https://www.harery.com)
[![Email](https://img.shields.io/badge/Email-Mohamed%40Harery.com-red?style=flat-square)](mailto:Mohamed@Harery.com)
[![GitHub](https://img.shields.io/badge/GitHub-Harery-black?style=flat-square&logo=github)](https://github.com/Harery)

---

**MIT Licensed** • **Production Ready** • **Safe to Run Dry-First**

[⬆️ Back to Top](#️-sysmaint)

</div>
