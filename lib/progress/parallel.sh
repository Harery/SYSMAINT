#!/usr/bin/env bash
# lib/progress/parallel.sh - DAG-based parallel execution engine
# sysmaint library

_deps_satisfied() {
  local phase="$1"
  local deps="${PHASE_DEPS[$phase]}"
  [[ -z "$deps" ]] && return 0
  local dep
  IFS=',' read -ra dep_arr <<< "$deps"
  for dep in "${dep_arr[@]}"; do
    [[ "${PHASE_COMPLETED[$dep]:-false}" != "true" ]] && return 1
  done
  return 0
}

_compute_execution_groups() {
  # Build groups: each group = set of phases with satisfied deps that can run concurrently
  EXECUTION_GROUPS=()
  PHASE_COMPLETED=()
  local remaining=()
  local p
  for p in "${INCLUDED_PHASES[@]}"; do
    remaining+=("$p")
  done
  
  while (( ${#remaining[@]} > 0 )); do
    local ready=()
    local still_waiting=()
    for p in "${remaining[@]}"; do
      if _deps_satisfied "$p"; then
        ready+=("$p")
      else
        still_waiting+=("$p")
      fi
    done
    
    if (( ${#ready[@]} == 0 )); then
      log "ERROR: Dependency cycle or unsatisfiable deps in: ${still_waiting[*]}"
      break
    fi
    
    # Add ready group
    EXECUTION_GROUPS+=("${ready[*]}")
    for p in "${ready[@]}"; do
      PHASE_COMPLETED[$p]=true
    done
    remaining=("${still_waiting[@]}")
  done
}

_run_phase_parallel() {
  # Execute a single phase in a subshell for parallel execution
  local phase="$1"
  (
      set +e  # Disable errexit in subshell to handle phase errors gracefully
      trap - ERR  # Disable ERR trap in subshell
    record_phase_start "$phase"
    update_status_panel_phase "$phase"
    case "$phase" in
      clean_tmp) clean_tmp || true ;;
      fix_broken) fix_broken_if_any ;;
      validate_repos) validate_repos ;;
      detect_missing_pubkeys) detect_missing_pubkeys ;;
      fix_missing_pubkeys) fix_missing_pubkeys || true ;;
      kernel_status) kernel_status ;;
      apt_maintenance) apt_maintenance ;;
  post_kernel_finalize) post_kernel_finalize ;;
      snap_maintenance) snap_maintenance ;;
      flatpak_maintenance) flatpak_maintenance ;;
      firmware_maintenance) firmware_maintenance ;;
      dns_maintenance) dns_maintenance ;;
      journal_maintenance) journal_maintenance ;;
      thumbnail_maintenance) thumbnail_maintenance ;;
      check_failed_services) check_failed_services ;;
      snap_cleanup_old) snap_cleanup_old ;;
      snap_clear_cache) snap_clear_cache ;;
        crash_dump_purge) crash_dump_purge ;;
        fstrim_phase) fstrim_phase ;;
      drop_caches_phase) drop_caches_phase ;;
      kernel_purge_phase) kernel_purge_phase ;;
      orphan_purge_phase) orphan_purge_phase ;;
      *) log "Unknown phase: $phase" ;;
    esac
    record_phase_end "$phase"
  )
}

execute_parallel() {
  log "=== Parallel execution mode enabled ==="
  _compute_included_phases
    for p in "${!PHASE_COMPLETED[@]}"; do
      unset "PHASE_COMPLETED[$p]"
    done
  _compute_execution_groups
  
  log "Execution plan: ${#EXECUTION_GROUPS[@]} groups"
  local gidx=0
  for group in "${EXECUTION_GROUPS[@]}"; do
      gidx=$((gidx + 1))
    log "Group $gidx: $group"
    local pids=()
    for phase in $group; do
      _run_phase_parallel "$phase" &
      pids+=($!)
    done
    # Wait for all phases in group to complete
      if (( ${#pids[@]} > 0 )); then
        for pid in "${pids[@]}"; do
          wait "$pid" || log "WARNING: Phase in group $gidx failed (PID $pid)"
        done
      fi
    log "Group $gidx completed"
  done
  log "=== Parallel execution complete ==="
}

