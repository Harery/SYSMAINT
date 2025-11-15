#!/usr/bin/env bash
# Param-driven Combo Test Suite
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
SYSMAINT="$REPO_ROOT/sysmaint"
export DRY_RUN=true JSON_SUMMARY=true

PASSED=0 FAILED=0 TOTAL=0
latest_json(){ ls -1t /tmp/system-maintenance/sysmaint_*.json 2>/dev/null | head -n1 || true; }

run_case(){ local name="$1"; shift; TOTAL=$((TOTAL+1)); echo -n "[COMBO $TOTAL] $name: ";
  set +e; bash "$SYSMAINT" "$@" >/dev/null 2>&1; rc=$?; set -e;
  if [[ $rc -eq 0 ]]; then echo "✅"; PASSED=$((PASSED+1)); else echo "❌ ($rc)"; FAILED=$((FAILED+1)); fi; }

UPGRADE_SET=("--upgrade" "--purge-kernels --keep-kernels=2" "--upgrade --purge-kernels --keep-kernels=2 --orphan-purge")
SECURITY_SET=("--security-audit" "--security-audit --check-zombies")
DISPLAY_SET=("--color=always --progress=spinner" "--color=never --progress=quiet" "--color=auto --progress=bar")
RESOURCE_SET=("--fstrim" "--drop-caches" "--fstrim --drop-caches")
DESKTOP_SET=("--browser-cache-report" "--browser-cache-purge --browser-cache-report")
NEGATION_SET=("--no-snap --no-flatpak" "--no-check-zombies --no-clear-tmp" "--no-journal-vacuum --journal-days=3")

for u in "${UPGRADE_SET[@]}"; do for s in "${SECURITY_SET[@]}"; do for d in "${DISPLAY_SET[@]}"; do run_case "upgrade+sec+display" $u $s $d --dry-run; done; done; done
for r in "${RESOURCE_SET[@]}"; do for ds in "${DESKTOP_SET[@]}"; do run_case "resource+desktop" $r $ds --dry-run; done; done
for n in "${NEGATION_SET[@]}"; do run_case "negations" $n --dry-run; done
run_case "security-upgrade-desktop-resources" --upgrade --security-audit --check-zombies --browser-cache-report --fstrim --drop-caches --dry-run

echo "Combo Suite Results: Passed=$PASSED Failed=$FAILED Total=$TOTAL"
[[ $FAILED -eq 0 ]] && exit 0 || exit 1
