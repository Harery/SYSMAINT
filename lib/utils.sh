#!/usr/bin/env bash
# lib/utils.sh — Core utility functions for sysmaint
# sysmaint library
# License: MIT (see LICENSE file in repository root)
# Author: Mohamed Elharery <Mohamed@Harery.com>
# Copyright (c) 2025 Mohamed Elharery
#
# Provides: logging, progress UI, state management, timing functions

# ===== Utility helper functions =====

_is_root_user() {
  [[ $EUID -eq 0 ]]
}

_init_state_dir() {
  if [[ -n "$STATE_DIR" ]]; then
    :
  elif _is_root_user; then
    STATE_DIR="/var/lib/sysmaint"
  else
    STATE_DIR="$HOME/.local/state/sysmaint"
  fi
  mkdir -p "$STATE_DIR" 2>/dev/null || true
}

_state_file() {
  _init_state_dir
  printf '%s' "$STATE_DIR/timings.json"
}

load_phase_estimates() {
  # Load persisted EMA timings if present
  local sf
  sf=$(_state_file)
  if [[ -f "$sf" ]]; then
    # Expect a simple JSON object: {"phase": seconds, ...}
    # Use awk/sed to parse conservatively to avoid external deps like jq
    while IFS= read -r line; do
      # match "key": value
      if [[ "$line" =~ \"([a-zA-Z0-9_]+)\"[[:space:]]*:[[:space:]]*([0-9]+(\.[0-9]+)?) ]]; then
        PHASE_EST_EMA["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"
      fi
    done <"$sf" || true
  fi
}

save_phase_estimates() {
  # Persist EMA timings to JSON
  local sf
  sf=$(_state_file)
  local k first=true
  {
    printf '{\n'
    for k in "${!PHASE_EST_EMA[@]}"; do
      if [[ "$first" == true ]]; then first=false; else printf ',\n'; fi
      printf '  "%s": %s' "$k" "${PHASE_EST_EMA[$k]}"
    done
    printf '\n}\n'
  } >"$sf" 2>/dev/null || true
}

_fmt_hms() {
  # formats seconds -> H:MM:SS or M:SS
  local s=$1
  if (( s < 0 )); then s=0; fi
  local h=$((s/3600)) m=$(((s%3600)/60)) sec=$((s%60))
  if (( h > 0 )); then
    printf '%d:%02d:%02d' "$h" "$m" "$sec"
  else
    printf '%d:%02d' "$m" "$sec"
  fi
}

_float_max() { awk -v a="$1" -v b="$2" 'BEGIN{printf "%.3f", (a>b)?a:b}'; }
_float_min() { awk -v a="$1" -v b="$2" 'BEGIN{printf "%.3f", (a<b)?a:b}'; }

_ema_update() {
  # args: key observed_seconds
  local k="$1" obs="$2"
  local prev="${PHASE_EST_EMA[$k]:-}"
  if [[ -z "$prev" ]]; then
    PHASE_EST_EMA[$k]="$obs"
  else
    # ema = alpha*obs + (1-alpha)*prev
    local alpha="$PROGRESS_ALPHA"
    local ema
    ema=$(awk -v a="$alpha" -v o="$obs" -v p="$prev" 'BEGIN{printf "%.3f", a*o + (1-a)*p}')
    PHASE_EST_EMA[$k]="$ema"
  fi
}

_phase_included() {
  local p="$1"
  case "$p" in
    snap_maintenance)
      [[ "${NO_SNAP:-false}" != "true" ]]
      ;;
    upgrade_finalize)
      [[ "${UPGRADE_PHASE_ENABLED:-false}" == "true" ]]
      ;;
    kernel_purge_phase)
      [[ "${PURGE_OLD_KERNELS:-false}" == "true" ]]
      ;;
    post_kernel_finalize)
      # Only meaningful if kernels were purged in this run
      [[ "${PURGE_OLD_KERNELS:-false}" == "true" ]]
      ;;
    orphan_purge_phase)
      [[ "${ORPHAN_PURGE_ENABLED:-false}" == "true" ]]
      ;;
    snap_cleanup_old)
      [[ "${NO_SNAP:-false}" != "true" && "${SNAP_CLEAN_OLD:-false}" == "true" ]]
      ;;
    snap_clear_cache)
      [[ "${NO_SNAP:-false}" != "true" && "${SNAP_CLEAR_CACHE:-false}" == "true" ]]
      ;;
    flatpak_maintenance)
      [[ "${NO_FLATPAK:-false}" != "true" ]]
      ;;
    firmware_maintenance)
      [[ "${NO_FIRMWARE:-false}" != "true" ]]
      ;;
    fix_missing_pubkeys)
      [[ "${FIX_MISSING_KEYS:-false}" == "true" ]]
      ;;
    crash_dump_purge)
      [[ "${CLEAR_CRASH_DUMPS:-true}" == "true" ]]
      ;;
    fstrim_phase)
      [[ "${FSTRIM_ENABLED:-false}" == "true" ]]
      ;;
    drop_caches_phase)
      [[ "${DROP_CACHES_ENABLED:-false}" == "true" ]]
      ;;
    browser_cache_phase)
      [[ "${BROWSER_CACHE_REPORT:-false}" == "true" || "${BROWSER_CACHE_PURGE:-false}" == "true" ]]
      ;;
    *)
      return 0
      ;;
  esac
}

_compute_included_phases() {
  INCLUDED_PHASES=()
  local p
  for p in "${PHASE_ORDER[@]}"; do
    if _phase_included "$p"; then
      INCLUDED_PHASES+=("$p")
    fi
  done
}

_est_for_phase() {
  local p="$1"
  if [[ -z "$p" ]]; then
    printf '%.3f' "5.000"
    return 0
  fi
  local est="${PHASE_EST_EMA[$p]:-}"
  if [[ -z "$est" ]]; then
    # conservative defaults by phase if unknown
    case "$p" in
      clean_tmp) est=2 ;;
      fix_broken) est=3 ;;
      validate_repos) est=4 ;;
      detect_missing_pubkeys) est=2 ;;
      fix_missing_pubkeys) est=8 ;;
      kernel_status) est=2 ;;
      apt_maintenance) est=120 ;;
      kernel_purge_phase) est=18 ;;
      post_kernel_finalize) est=12 ;;
      orphan_purge_phase) est=15 ;;
      snap_maintenance) est=45 ;;
      snap_cleanup_old) est=20 ;;
      snap_clear_cache) est=8 ;;
      crash_dump_purge) est=10 ;;
      fstrim_phase) est=12 ;;
      drop_caches_phase) est=5 ;;
      flatpak_maintenance) est=40 ;;
      firmware_maintenance) est=25 ;;
      dns_maintenance) est=4 ;;
      journal_maintenance) est=6 ;;
      thumbnail_maintenance) est=5 ;;
      check_failed_services) est=3 ;;
      *) est=5 ;;
    esac
  fi
  # Apply host scaling: CPU for compute-heavy, NETWORK for repo/pubkey, RAM for large caches
  local scale=1.0
  case "$p" in
    validate_repos|detect_missing_pubkeys|apt_maintenance|snap_maintenance|flatpak_maintenance)
      scale=$(awk -v c="$CPU_SCALE" -v n="$NETWORK_SCALE" 'BEGIN{printf "%.3f", c*n}')
      ;;
    journal_maintenance|thumbnail_maintenance|clean_tmp)
      scale="$RAM_SCALE"
      ;;
    firmware_maintenance|kernel_status)
      scale="$CPU_SCALE"
      ;;
    dns_maintenance)
      scale="$NETWORK_SCALE"
      ;;
    check_failed_services)
      scale="$CPU_SCALE"
      ;;
    *) scale=1.0 ;;
  esac
  est=$(awk -v e="$est" -v s="$scale" 'BEGIN{printf "%.3f", e*s}')
  printf '%.3f' "$est"
}

_sum_est_total() {
  local total=0 p est
  for p in "${INCLUDED_PHASES[@]}"; do
    est=$(_est_for_phase "$p")
    total=$(awk -v t="$total" -v e="$est" 'BEGIN{printf "%.3f", t+e}')
  done
  printf '%.3f' "$total"
}

_sum_elapsed_so_far() {
  local total=0 p key
  for p in "${INCLUDED_PHASES[@]}"; do
    key="${p}_duration"
    if [[ -n "${PHASE_TIMINGS[$key]:-}" ]]; then
      total=$(awk -v t="$total" -v d="${PHASE_TIMINGS[$key]}" 'BEGIN{printf "%.3f", t+d}')
    else
      # Not yet completed -> stop summing here
      break
    fi
  done
  printf '%.3f' "$total"
}

# Collect host profile (CPU cores, total RAM MB, network RTT ms to archive.ubuntu.com)
_collect_host_profile() {
  local cores ram_kb ram_mb rtt host_json rtt_ms ts profile_file
  cores=$(getconf _NPROCESSORS_ONLN 2>/dev/null || nproc 2>/dev/null || echo 1)
  ram_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)
  ram_mb=$((ram_kb/1024))
  # Simple RTT measurement (first successful ping) fallback to 999 if unavailable
  if command -v ping >/dev/null 2>&1; then
    rtt=$(ping -c1 -w2 archive.ubuntu.com 2>/dev/null | awk -F'/' '/rtt/ {print $5}')
  fi
  rtt_ms=${rtt:-999.0}
  ts=$(date --iso-8601=seconds)
  host_json=$(cat <<EOF
{
  "timestamp": "${ts}",
  "cpu_cores": ${cores},
  "ram_mb": ${ram_mb},
  "network_rtt_ms": ${rtt_ms}
}
EOF
)
  profile_file="$STATE_DIR/host_profile.json"
  printf '%s\n' "$host_json" >"$profile_file" 2>/dev/null || true
  # Derive scaling factors (heuristic):
  # CPU: if cores >=8 -> 0.85, >=4 -> 0.9 else 1.0 (faster cores reduce estimate)
  if (( cores >= 8 )); then CPU_SCALE=0.85; elif (( cores >= 4 )); then CPU_SCALE=0.90; else CPU_SCALE=1.00; fi
  # RAM: if ram_mb < 2048 -> 1.10 (slower), <4096 -> 1.05 else 1.0
  if (( ram_mb < 2048 )); then RAM_SCALE=1.10; elif (( ram_mb < 4096 )); then RAM_SCALE=1.05; else RAM_SCALE=1.00; fi
  # Network: if rtt_ms > 200 -> 1.20, >100 ->1.10, >50 ->1.05 else 1.0
  rtt_int=$(printf '%.0f' "$rtt_ms" 2>/dev/null || echo 999)
  if (( rtt_int > 200 )); then NETWORK_SCALE=1.20; elif (( rtt_int > 100 )); then NETWORK_SCALE=1.10; elif (( rtt_int > 50 )); then NETWORK_SCALE=1.05; else NETWORK_SCALE=1.00; fi
}

_progress_snapshot() {
  # outputs: overall_pct overall_elapsed overall_eta phase_pct phase_elapsed phase_est next1 next2
  local total_est elapsed_completed phase_est phase_elapsed overall_elapsed overall_pct remaining eta_sec phase_pct next1 next2
  total_est=$(_sum_est_total)
  elapsed_completed=$(_sum_elapsed_so_far)

  phase_est=$(_est_for_phase "$CURRENT_PHASE")
  if (( CURRENT_PHASE_START_TS > 0 )); then
    phase_elapsed=$(( $(date +%s) - CURRENT_PHASE_START_TS ))
  else
    phase_elapsed=0
  fi
  # Clamp per-phase progress to < 100% until phase ends
  phase_pct=$(awk -v e="$phase_elapsed" -v est="$phase_est" 'BEGIN{pct=(est>0? (100*e/est) : 0); if(pct>99) pct=99; if(pct<0) pct=0; printf "%d", pct}')

  overall_elapsed=$(awk -v c="$elapsed_completed" -v pe="$phase_elapsed" 'BEGIN{printf "%.3f", c+pe}')
  remaining=$(awk -v t="$total_est" -v e="$overall_elapsed" 'BEGIN{r=t-e; if(r<0) r=0; printf "%.3f", r}')
  eta_sec=$(printf '%.0f' "$remaining")
  if (( $(printf '%.0f' "$total_est") > 0 )); then
    overall_pct=$(awk -v e="$overall_elapsed" -v t="$total_est" 'BEGIN{pct=(t>0? (100*e/t) : 0); if(pct>100)pct=100; if(pct<0)pct=0; printf "%d", pct}')
  else
    overall_pct=0
  fi

  # Compute next phases labels
  next1=""; next2=""
  local i
  for ((i=0; i<${#INCLUDED_PHASES[@]}; i++)); do
    if [[ "${INCLUDED_PHASES[$i]}" == "$CURRENT_PHASE" ]]; then
      if (( i+1 < ${#INCLUDED_PHASES[@]} )); then
        next1="${INCLUDED_PHASES[$i+1]}"
      fi
      if (( i+2 < ${#INCLUDED_PHASES[@]} )); then
        next2="${INCLUDED_PHASES[$i+2]}"
      fi
      break
    fi
  done
  printf '%d %d %d %d %d %s %s' "$overall_pct" "$(printf '%.0f' "$overall_elapsed")" "$eta_sec" "$phase_pct" "$phase_elapsed" "$next1" "$next2"
}

_render_bar() {
  # args: pct width
  local pct=$1 width=$2
  local filled=$((pct * width / 100))
  local empty=$((width - filled))
  printf '['
  for ((i=0; i<filled; i++)); do printf '='; done
  for ((i=0; i<empty; i++)); do printf ' '; done
  printf ']'
}

update_status_panel_phase() {
  # args: phase_name
  local p="$1"
  CURRENT_PHASE="$p"
  CURRENT_PHASE_START_TS=$(date +%s)
}

stop_status_panel() {
  if [[ -n "$STATUS_PANEL_PID" ]]; then
    STATUS_PANEL_ACTIVE=false
    # Give the loop a moment to exit gracefully
    sleep "$PROGRESS_REFRESH"
    kill "$STATUS_PANEL_PID" >/dev/null 2>&1 || true
    wait "$STATUS_PANEL_PID" 2>/dev/null || true
    STATUS_PANEL_PID=""
  fi
}

# ===== Logging functions =====

log() {
  local plain
  plain=$(printf '%s %s' "$(date '+%F %T')" "$*")
  printf '%s\n' "$plain" >>"$LOG_FILE"

  # Determine color usage based on COLOR_MODE (auto|always|never) and NO_COLOR
  local use_color
  case "${COLOR_MODE:-auto}" in
    always) use_color=true ;;
    never) use_color=false ;;
    *) if [[ -t 1 && "${NO_COLOR:-}" != "true" ]]; then use_color=true; else use_color=false; fi ;;
  esac
  if [[ "$use_color" != "true" ]]; then
    printf '%s\n' "$plain"
    return 0
  fi

  local COLOR_RESET="\033[0m"
  local COLOR_INFO="\033[1;34m"
  local COLOR_OK="\033[1;32m"
  local COLOR_WARN="\033[1;33m"
  local COLOR_ERR="\033[1;31m"
  local COLOR_CMD="\033[1;36m"
  local COLOR_FINAL_RED="\033[1;31m"
  local COLOR_FINAL_PURPLE="\033[1;35m"
  local COLOR_FINAL_ORANGE="\033[1;38;5;214m"
  local color="$COLOR_INFO"
  case "$*" in
    Logging*) color="$COLOR_FINAL_RED" ;;
    Log\ directory:*) color="$COLOR_FINAL_PURPLE" ;;
    Log\ file\ name:*) color="$COLOR_FINAL_ORANGE" ;;
    ERROR* | *ERROR:*) color="$COLOR_ERR" ;;
    +*) color="$COLOR_CMD" ;;
    DRY_RUN:*) color="$COLOR_WARN" ;;
    ===*) color="$COLOR_OK" ;;
  esac
  printf '%b\n' "${color}${plain}${COLOR_RESET}"
}

run() {
  log "+ $*"
  # In DRY_RUN mode, don't execute commands — just log them.
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "DRY_RUN: would run: $*"
    return 0
  fi

  # tee in a subshell to capture exit code correctly
  set +e
  output=$("$@" 2>&1)
  rc=$?
  set -e
  printf '%s\n' "$output" | tee -a "$LOG_FILE"
  return $rc
}

# ===== Progress UI (moved from lib/progress.sh) =====

show_progress() {
  # args: duration mode message
  local duration=${1:-$PROGRESS_DURATION}
  local mode=${2:-$PROGRESS_MODE}
  local msg=${3:-}

  # Only show if stdout is a TTY and mode is not 'none'
  if [[ "$mode" == "none" || ! -t 1 ]]; then
    return 0
  fi

  if [[ -n "$msg" ]]; then
    printf '%s ' "$msg" >&2
  fi

  case "$mode" in
  dots)
    for ((i=0; i<duration; i++)); do
      printf '.' >&2
      sleep 1
    done
    printf '\n' >&2
    ;;
  countdown)
    for ((i=duration; i>0; i--)); do
      printf '%d.. ' "$i" >&2
      sleep 1
    done
    printf '\n' >&2
    ;;
  bar)
    # Simple textual progress bar: fills over the specified duration in 20 steps
    local steps=20
    local step_duration
    if (( duration < steps )); then
      steps=$duration
    fi
    if (( steps > 0 )); then
      step_duration=$(awk -v d="$duration" -v s="$steps" 'BEGIN {printf "%.3f", d/s}')
    else
      step_duration=0
    fi
    local i filled pct
    printf '\n' >&2
    for ((i=1; i<=steps; i++)); do
      filled=$(( (i * 100) / steps ))
      pct=$filled
      # Build bar string
      local bar_fill=$(( (i * 20) / steps ))
      local bar
      bar=$(printf '%*s' 20 '' | tr ' ' '#')
      local filled_part=${bar:0:bar_fill}
      local empty_part
      empty_part=$(printf '%*s' $((20-bar_fill)) '' | tr ' ' ' ')
      printf '\r[%s%s] %3d%% %s' "$filled_part" "$empty_part" "$pct" "$msg" >&2
      sleep "$step_duration"
    done
    printf '\r[%s] 100%% %s\n' "####################" "$msg" >&2
    ;;
  spinner)
    # Animated spinner for the specified duration (seconds)
    local frames='|/-\\'
    local end_time=$(( $(date +%s) + duration ))
    local idx=0 ch now
    printf '\n' >&2
    while true; do
      now=$(date +%s)
      if (( now >= end_time )); then
        break
      fi
      ch=${frames:idx:1}
      printf '\r[%c] %s' "$ch" "$msg" >&2
      sleep 0.1
      ((idx=(idx+1)%${#frames}))
    done
    printf '\r[✔] %s\n' "$msg" >&2
    ;;
  adaptive)
    # No-op here: the adaptive multi-line panel is managed separately as a long-lived background task.
    ;;
  *)
    # unknown mode: no-op
    ;;
  esac
}

start_status_panel() {
  # Only on TTY and when mode=adaptive
  if [[ "$PROGRESS_MODE" != "adaptive" || ! -t 1 ]]; then
    return 0
  fi

  load_phase_estimates
  _compute_included_phases
  STATUS_PANEL_ACTIVE=true

  # Background refresher
  (
    printf '\n\n\n' >&2 # reserve 3 lines
    while $STATUS_PANEL_ACTIVE; do
      read -r opct osec eta ppct psec n1 n2 < <(_progress_snapshot)
      # Move cursor up 3 lines, carriage return
      printf '\033[3F\r' >&2
      # Line 1: overall
      printf ' Overall ' >&2; _render_bar "$opct" "$PROGRESS_WIDTH" >&2; printf '  Elapsed: %s  ETA: %s          \n' "$(_fmt_hms "$osec")" "$(_fmt_hms "$eta")" >&2
      # Line 2: phase
      local pdisp="$CURRENT_PHASE"; [[ -z "$pdisp" ]] && pdisp="starting"
      printf ' Phase   ' >&2; _render_bar "$ppct" "$PROGRESS_PHASE_WIDTH" >&2; printf '  %-22s %s/%s          \n' "$pdisp" "$(_fmt_hms "$psec")" "$(_fmt_hms "$(printf '%.0f' "$(_est_for_phase "$CURRENT_PHASE")")")" >&2
      # Line 3: next
      local nextline="Next: $n1"; [[ -n "$n2" ]] && nextline+=", $n2"
      printf ' %s\033[K\n' "$nextline" >&2
      sleep "$PROGRESS_REFRESH"
    done
    # Clean up panel area when done
    printf '\033[3F\r\033[J' >&2
  ) &
  STATUS_PANEL_PID=$!
}
