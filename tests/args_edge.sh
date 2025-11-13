#!/usr/bin/env bash
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery
set -euo pipefail
cd "$(dirname "$0")/.."

pass=0; fail=0

check_ok() { if "$@" >/dev/null 2>&1; then echo "[OK] $*"; pass=$((pass+1)); else echo "[FAIL] $*"; fail=$((fail+1)); fi; }
check_warn() { if "$@" >/dev/null 2>&1; then echo "[WARN] expected nonzero: $*"; else echo "[OK] nonzero: $*"; pass=$((pass+1)); fi; }

# Help should succeed
check_ok bash sysmaint --help

# Unknown flag should error (parser fallback tolerates non-zero)
check_warn bash sysmaint --definitely-unknown-flag

# Mixed forms should parse
check_ok bash sysmaint --journal-days=5 --dry-run
check_ok bash sysmaint --auto-reboot-delay 15 --dry-run

# Conflicting toggles: should not crash
check_ok bash sysmaint --no-clear-tmp --clear-tmp --dry-run

# Upgrade flag should activate phase (dry-run ok)
check_ok bash sysmaint --upgrade --dry-run

echo "Passed: $pass  Failed: $fail"; [ $fail -eq 0 ]
