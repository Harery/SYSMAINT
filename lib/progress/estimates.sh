#!/usr/bin/env bash
# lib/progress/estimates.sh - Phase timing estimation and EMA calculations
# sysmaint library

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

record_phase_start() {
  local phase_name="$1"
  PHASE_TIMINGS["${phase_name}_start"]=$(date +%s)
  # Capture disk usage at phase start
  local disk_kb
  disk_kb=$(df -P / | awk 'NR==2 {print $3}')
  PHASE_TIMINGS["${phase_name}_disk_start"]=$disk_kb
}

record_phase_end() {
  local phase_name="$1"
  local start_key="${phase_name}_start"
  local end_ts duration
  end_ts=$(date +%s)
  PHASE_TIMINGS["${phase_name}_end"]=$end_ts
  if [[ -n "${PHASE_TIMINGS[$start_key]:-}" ]]; then
    duration=$((end_ts - PHASE_TIMINGS[$start_key]))
    PHASE_TIMINGS["${phase_name}_duration"]=$duration
    # Update EMA timing database for adaptive progress (ignore zero / extremely short sub-second durations)
    if (( duration > 0 )); then
      _ema_update "$phase_name" "$duration"
      save_phase_estimates
    fi
  fi
  # Capture disk usage at phase end and compute delta
  local disk_start_key="${phase_name}_disk_start"
  if [[ -n "${PHASE_TIMINGS[$disk_start_key]:-}" ]]; then
    local disk_kb_end disk_delta
    disk_kb_end=$(df -P / | awk 'NR==2 {print $3}')
    disk_delta=$((PHASE_TIMINGS[$disk_start_key] - disk_kb_end))
    PHASE_DISK_DELTAS["${phase_name}"]=$disk_delta
  fi
}
