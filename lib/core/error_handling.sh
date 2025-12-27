#!/usr/bin/env bash
# lib/core/error_handling.sh - Error handling and cleanup
# sysmaint library
# Copyright (c) 2025 Mohamed Elharery

# Functions:
#   on_exit()                 - Exit trap handler for cleanup
#   on_err()                  - Error trap handler for debugging
#   load_phase_estimates()    - Load historical timing data
#   save_phase_estimates()    - Persist timing data to disk

# This module handles error traps, exit cleanup, and lock file management.
# It ensures proper cleanup even when the script exits unexpectedly.

# Traps:
#   EXIT - on_exit() releases locks, cleans temp files
#   ERR  - on_err() logs error location for debugging

load_phase_estimates() {
  # Load EMA timings from JSON
  local sf
  sf=$(_state_file)
  if [[ ! -f "$sf" ]]; then
    return 0
  fi
  # Parse JSON manually with grep+sed
  while IFS=: read -r key val; do
    # Remove leading/trailing whitespace, quotes, commas
    key=$(printf '%s' "$key" | sed -e 's/^[[:space:]]*"//' -e 's/"[[:space:]]*$//')
    val=$(printf '%s' "$val" | sed -e 's/^[[:space:]]*//' -e 's/[,[:space:]]*$//')
    if [[ -n "$key" && -n "$val" ]]; then
      PHASE_EST_EMA["$key"]="$val"
    fi
  done < <(grep -E '"[^"]+":' "$sf" 2>/dev/null || true)
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

on_exit() {
  # global cleanup on script exit
  local ec=$?
  # Only print summary if not already printed
  if [[ "${SUMMARY_PRINTED:-false}" == "false" ]]; then
    print_summary || true
    SUMMARY_PRINTED=true
  fi
  stop_status_panel || true
  if [[ -n "${LOCKFILE:-}" && -f "$LOCKFILE" ]]; then
    rm -f "$LOCKFILE" 2>/dev/null || true
  fi
  if [[ -n "${PIDFILE:-}" && -f "$PIDFILE" ]]; then
    rm -f "$PIDFILE" 2>/dev/null || true
  fi
  # Close file descriptor if opened
  if [[ -n "${LOCK_FD:-}" ]]; then
    exec 200>&- 2>/dev/null || true
  fi
  exit "$ec"
}

on_err() {
  # This trap is called on any error unless _SM_IGNORED_ERR=1 is set
  # immediately before the command that might fail.
  if [[ "${_SM_IGNORED_ERR:-0}" == "1" ]]; then
    _SM_IGNORED_ERR=0
    return 0
  fi
  log "ERROR: command failed at line ${BASH_LINENO[0]}"
}
