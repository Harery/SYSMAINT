#!/usr/bin/env bash
# Tier 1 profile launcher for sysmaint (Stage 2 progressive UI)
# Provides curated presets with time/risk guidance and a confirmation flow.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSMAINT_BIN="${SYSMAINT_BIN:-$SCRIPT_DIR/sysmaint}"

if [[ ! -x "$SYSMAINT_BIN" ]]; then
  echo "ERROR: sysmaint binary not found at $SYSMAINT_BIN" >&2
  exit 1
fi

PROFILE_KEYS=(minimal standard desktop server aggressive)

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
Usage: ./sysmaint_profiles.sh [options] [extra sysmaint flags...]

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
  printf '--------------------------------------------------------------\n'
  local idx=1 key
  for key in "${PROFILE_KEYS[@]}"; do
    printf '%d) %-10s — %s\n' "$idx" "${PROFILE_NAME[$key]}" "${PROFILE_DESC[$key]}"
    idx=$((idx + 1))
  done
  printf '\n'
}

PROMPT_CHOICE=""
ASSUME_YES=false
PRINT_ONLY=false
EXTRA_FLAGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--profile)
      PROMPT_CHOICE="$2"
      shift 2
      ;;
    --list)
      list_profiles
      exit 0
      ;;
    -y|--yes)
      ASSUME_YES=true
      shift
      ;;
    --print-command)
      PRINT_ONLY=true
      shift
      ;;
    --sysmaint)
      SYSMAINT_BIN="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do
        EXTRA_FLAGS+=("$1")
        shift
      done
      break
      ;;
    *)
      EXTRA_FLAGS+=("$1")
      shift
      ;;
  esac
done

choose_profile() {
  local choice key
  while true; do
    read -r -p "Select profile [1-${#PROFILE_KEYS[@]}]: " choice || return 1
    if [[ "$choice" =~ ^[1-9][0-9]*$ ]] && (( choice >= 1 && choice <= ${#PROFILE_KEYS[@]} )); then
      key="${PROFILE_KEYS[$((choice-1))]}"
      printf '%s' "$key"
      return 0
    fi
    echo "Invalid selection. Please choose a number between 1 and ${#PROFILE_KEYS[@]}."
  done
}

profile_key="${PROMPT_CHOICE:-}"
if [[ -z "$profile_key" ]]; then
  if [[ ! -t 0 ]]; then
    echo "ERROR: --profile is required when stdin is non-interactive." >&2
    usage
    exit 1
  fi
  list_profiles
  profile_key="$(choose_profile)" || exit 1
fi

profile_key="${profile_key,,}"  # lowercase

if [[ -z "${PROFILE_FLAGS[$profile_key]+x}" ]]; then
  echo "ERROR: unknown profile '$profile_key'. Use --list to view valid keys." >&2
  exit 1
fi

# Build argument array
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
  echo "Command : $SYSMAINT_BIN ${cmd_args[*]}"
  echo ""
}

summary

if [[ "$PRINT_ONLY" == "true" ]]; then
  echo "$SYSMAINT_BIN ${cmd_args[*]}"
  exit 0
fi

if [[ "$ASSUME_YES" != "true" ]]; then
  read -r -p "Proceed with this profile? [y/N]: " confirm || exit 1
  case "${confirm,,}" in
    y|yes)
      ;;
    *)
      echo "Aborted by user."
      exit 0
      ;;
  esac
fi

echo "Launching sysmaint..."
exec "$SYSMAINT_BIN" "${cmd_args[@]}"
