#!/usr/bin/env bash
# lib/subcommands.sh — Embedded subcommands for sysmaint
# sysmaint library
# License: MIT (see LICENSE file in repository root)
# Author: Mohamed Elharery <Mohamed@Harery.com>
# Copyright (c) 2025 Mohamed Elharery
#
# Provides: scanners_main, profiles_main
# These are standalone entry points for external security scanners and preset profiles

scanners_main() {
  set -euo pipefail
  local out_dir
  out_dir=${OUT_DIR:-"${SCRIPT_DIR}/scanner_artifacts"}
  mkdir -p "$out_dir"

  local ts summary_file lynis_report rkhunter_report
  ts=$(date -u +'%Y%m%dT%H%M%SZ')
  summary_file="$out_dir/summary_${ts}.json"
  lynis_report="$out_dir/lynis_${ts}.log"
  rkhunter_report="$out_dir/rkhunter_${ts}.log"

  local scan_lynis scan_rkhunter
  scan_lynis=${SCAN_LYNIS:-true}
  scan_rkhunter=${SCAN_RKHUNTER:-true}

  local lynis_min rkh_max_warn rkh_max_rootkits
  lynis_min=${LYNIS_MIN_SCORE:-80}
  rkh_max_warn=${RKHUNTER_MAX_WARNINGS:-5}
  rkh_max_rootkits=${RKHUNTER_MAX_ROOTKITS:-0}

  local retention_days
  retention_days=${RETENTION_DAYS:-30}

  echo "[scanners] Starting external scanners orchestration at $ts"
  echo "[scanners] Thresholds: lynis_min=$lynis_min rkhunter_max_warnings=$rkh_max_warn"

  run_lynis() {
    command -v lynis >/dev/null 2>&1 || { echo "[scanners] lynis not installed, skipping"; return 0; }
    echo "[scanners] Running lynis audit --quick" >&2
    if lynis audit system --quick --no-colors --quiet >"$lynis_report" 2>&1; then
      echo "[scanners] lynis completed" >&2
    else
      echo "[scanners] lynis failed (non-zero exit)" >&2
    fi
  }

  run_rkhunter() {
    command -v rkhunter >/dev/null 2>&1 || { echo "[scanners] rkhunter not installed, skipping"; return 0; }
    echo "[scanners] Running rkhunter --check --sk" >&2
    if rkhunter --check --sk --nocolors --logfile "$rkhunter_report" >/dev/null 2>&1; then
      echo "[scanners] rkhunter completed" >&2
    else
      echo "[scanners] rkhunter encountered warnings/errors" >&2
    fi
  }

  local lynis_score="" rkh_warnings="" rkh_rootkits=""

  if [[ "$scan_lynis" == "true" ]]; then
    run_lynis
    if [[ -s "$lynis_report" ]]; then
      lynis_score=$(grep -E "Hardening index" "$lynis_report" | awk '{print $NF}' || true)
    fi
  fi

  if [[ "$scan_rkhunter" == "true" ]]; then
    run_rkhunter
    if [[ -s "$rkhunter_report" ]]; then
      rkh_warnings=$(grep -c "[Warning]" "$rkhunter_report" || echo 0)
      rkh_rootkits=$(grep -c "Rootkit" "$rkhunter_report" || echo 0)
    fi
  fi

  cat >"$summary_file" <<JSON
{
  "timestamp": "$ts",
  "lynis_invoked": $( [[ "$scan_lynis" == "true" && -s "$lynis_report" ]] && echo true || echo false ),
  "lynis_score": "${lynis_score}",
  "rkhunter_invoked": $( [[ "$scan_rkhunter" == "true" && -s "$rkhunter_report" ]] && echo true || echo false ),
  "rkhunter_warnings": "${rkh_warnings}",
  "rkhunter_rootkit_refs": "${rkh_rootkits}",
  "artifacts": {
    "lynis_report": "$( [[ -s "$lynis_report" ]] && basename "$lynis_report" || echo "")",
    "rkhunter_report": "$( [[ -s "$rkhunter_report" ]] && basename "$rkhunter_report" || echo "")"
  }
}
JSON

  echo "[scanners] Summary written: $summary_file"

  if [[ -d "$out_dir" ]]; then
    find "$out_dir" -name "summary_*.json" -mtime +"$retention_days" -delete 2>/dev/null || true
    find "$out_dir" -name "lynis_*.log" -mtime +"$retention_days" -delete 2>/dev/null || true
    find "$out_dir" -name "rkhunter_*.log" -mtime +"$retention_days" -delete 2>/dev/null || true
    echo "[scanners] Cleaned artifacts older than $retention_days days"
  fi

  local failures=0
  if [[ -n "$lynis_score" ]]; then
    local score_num
    score_num=$(echo "$lynis_score" | grep -oE '[0-9]+' | head -1 || echo "0")
    if (( score_num > 0 && score_num < lynis_min )); then
      echo "[scanners] ❌ FAIL: Lynis score $score_num below threshold $lynis_min" >&2
      ((failures++))
    else
      echo "[scanners] ✅ PASS: Lynis score $score_num (threshold: $lynis_min)"
    fi
  fi

  if [[ -n "$rkh_warnings" && "$rkh_warnings" != "0" ]]; then
    if (( rkh_warnings > rkh_max_warn )); then
      echo "[scanners] ❌ FAIL: rkhunter warnings $rkh_warnings exceed threshold $rkh_max_warn" >&2
      ((failures++))
    else
      echo "[scanners] ⚠ WARNING: rkhunter warnings $rkh_warnings (threshold: $rkh_max_warn)"
    fi
  fi

  if [[ -n "$rkh_rootkits" && "$rkh_rootkits" != "0" ]]; then
    if (( rkh_rootkits > rkh_max_rootkits )); then
      echo "[scanners] ❌ FAIL: rkhunter rootkit refs $rkh_rootkits exceed threshold $rkh_max_rootkits" >&2
      ((failures++))
    fi
  fi

  if (( failures > 0 )); then
    echo "[scanners] Done with $failures failure(s)"; return 1
  fi
  echo "[scanners] Done - all thresholds passed"
  return 0
}

profiles_main() {
  set -euo pipefail
  local sysmaint_bin
  sysmaint_bin="${SYSMAINT_BIN:-$0}"

  local -a PROFILE_KEYS=(minimal standard desktop server aggressive)
  declare -A PROFILE_NAME PROFILE_DESC PROFILE_FLAGS PROFILE_EST PROFILE_RISK PROFILE_NOTES

  PROFILE_NAME[minimal]="Minimal Preview"
  PROFILE_DESC[minimal]="Safest dry-run overview with JSON telemetry"
  PROFILE_FLAGS[minimal]="--dry-run --json-summary"
  PROFILE_EST[minimal]="~2 minutes"
  PROFILE_RISK[minimal]="None"
  PROFILE_NOTES[minimal]="Use on first-time hosts to inspect impact and telemetry."

  PROFILE_NAME[standard]="Standard Autopilot"
  PROFILE_DESC[standard]="Recommended weekly run with autopilot + JSON"
  PROFILE_FLAGS[standard]="--json-summary --auto --auto-reboot-delay 45"
  PROFILE_EST[standard]="~5 minutes"
  PROFILE_RISK[standard]="Low"
  PROFILE_NOTES[standard]="Applies default maintenance phases and schedules reboot if required."

  PROFILE_NAME[desktop]="Desktop Cleanup"
  PROFILE_DESC[desktop]="Adds browser cache purge + colorful progress"
  PROFILE_FLAGS[desktop]="--json-summary --browser-cache-report --browser-cache-purge --color=always --progress=spinner --auto-reboot-delay 60"
  PROFILE_EST[desktop]="~6 minutes"
  PROFILE_RISK[desktop]="Medium"
  PROFILE_NOTES[desktop]="Great for personal laptops; browser caches removed and progress UI enabled."

  PROFILE_NAME[server]="Server Hardened"
  PROFILE_DESC[server]="Security-focused run with audits and zombie scans"
  PROFILE_FLAGS[server]="--json-summary --upgrade --check-zombies --security-audit --auto --auto-reboot-delay 120"
  PROFILE_EST[server]="~8 minutes"
  PROFILE_RISK[server]="Medium"
  PROFILE_NOTES[server]="Ideal for unattended servers; performs upgrade + diagnostics before rebooting if needed."

  PROFILE_NAME[aggressive]="Aggressive Cleanup"
  PROFILE_DESC[aggressive]="Deep cleanup with kernel purge + trims"
  PROFILE_FLAGS[aggressive]="--json-summary --upgrade --purge-kernels --keep-kernels=2 --orphan-purge --fstrim --drop-caches --snap-clean-old --snap-clear-cache"
  PROFILE_EST[aggressive]="~10 minutes"
  PROFILE_RISK[aggressive]="High"
  PROFILE_NOTES[aggressive]="Only run on well-tested hosts; aggressively reclaims disk space."

  usage() {
    cat <<'USAGE'
Usage: sysmaint profiles [options] [extra sysmaint flags...]

Options:
  -p, --profile <key>   Run the given profile non-interactively (minimal, standard, desktop, server, aggressive)
      --list            Print available profiles and exit
  -y, --yes             Skip confirmation prompt
      --print-command   Output the resolved sysmaint command and exit (no execution)
      --sysmaint <path> Use an alternate sysmaint binary
  -h, --help            Show this help text

Any additional flags after the options are appended to the generated sysmaint command.
USAGE
  }

  list_profiles() {
    printf '\nAvailable profiles (Tier 1)\n'
    echo '--------------------------------------------------------------'
    local idx=1 key
    for key in "${PROFILE_KEYS[@]}"; do
      printf '%d) %-10s - %s\n' "$idx" "${PROFILE_NAME[$key]}" "${PROFILE_DESC[$key]}"
      idx=$((idx + 1))
    done
    printf '\n'
  }

  local PROMPT_CHOICE="" ASSUME_YES=false PRINT_ONLY=false
  local -a EXTRA_FLAGS=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p|--profile) PROMPT_CHOICE="$2"; shift 2;;
      --list) list_profiles; return 0;;
      -y|--yes) ASSUME_YES=true; shift;;
      --print-command) PRINT_ONLY=true; shift;;
      --sysmaint) sysmaint_bin="$2"; shift 2;;
      -h|--help) usage; return 0;;
      --) shift; while [[ $# -gt 0 ]]; do EXTRA_FLAGS+=("$1"); shift; done; break;;
      *) EXTRA_FLAGS+=("$1"); shift;;
    esac
  done

  choose_profile() {
    local choice key
    while true; do
      # Non-interactive mode (CI/CD): auto-select first profile
      if [[ "${NONINTERACTIVE:-false}" == "true" ]] || [[ "${CI:-false}" == "true" ]] || [[ ! -t 0 ]]; then
        choice=1
      else
        read -r -p "Select profile [1-${#PROFILE_KEYS[@]}]: " choice || return 1
      fi
      if [[ "$choice" =~ ^[1-9][0-9]*$ ]] && (( choice >= 1 && choice <= ${#PROFILE_KEYS[@]} )); then
        key="${PROFILE_KEYS[$((choice-1))]}"
        printf '%s' "$key"; return 0
      fi
      echo "Invalid selection. Please choose a number between 1 and ${#PROFILE_KEYS[@]}."
    done
  }

  local profile_key="${PROMPT_CHOICE:-}"
  if [[ -z "$profile_key" ]]; then
    if [[ ! -t 0 ]]; then
      echo "ERROR: --profile is required when stdin is non-interactive." >&2
      usage; return 1
    fi
    list_profiles
    profile_key="$(choose_profile)" || return 1
  fi
  profile_key="${profile_key,,}"
  if [[ -z "${PROFILE_FLAGS[$profile_key]+x}" ]]; then
    echo "ERROR: unknown profile '$profile_key'. Use --list to view valid keys." >&2
    return 1
  fi

  local -a profile_args cmd_args
  IFS=' ' read -r -a profile_args <<< "${PROFILE_FLAGS[$profile_key]}"
  cmd_args=("${profile_args[@]}" "${EXTRA_FLAGS[@]}")

  summary() {
    echo ""
    echo "Profile : ${PROFILE_NAME[$profile_key]} (${profile_key})"
    echo "Purpose : ${PROFILE_DESC[$profile_key]}"
    echo "Runtime : ${PROFILE_EST[$profile_key]}"
    echo "Risk    : ${PROFILE_RISK[$profile_key]}"
    echo "Notes   : ${PROFILE_NOTES[$profile_key]}"
    if ((${#EXTRA_FLAGS[@]} > 0)); then
      echo "Extra   : ${EXTRA_FLAGS[*]}"
    fi
    echo "Command : $sysmaint_bin ${cmd_args[*]}"
    echo ""
  }
  summary

  if [[ "$PRINT_ONLY" == "true" ]]; then
    echo "$sysmaint_bin ${cmd_args[*]}"; return 0
  fi

  if [[ "$ASSUME_YES" != "true" ]]; then
    # Non-interactive mode (CI/CD): auto-confirm
    if [[ "${NONINTERACTIVE:-false}" == "true" ]] || [[ "${CI:-false}" == "true" ]] || [[ ! -t 0 ]]; then
      confirm="y"
    else
      read -r -p "Proceed with this profile? [y/N]: " confirm || return 1
    fi
    case "${confirm,,}" in y|yes) ;; *) echo "Aborted by user."; return 0;; esac
  fi

  echo "Launching sysmaint..."
  exec "$sysmaint_bin" "${cmd_args[@]}"
}
