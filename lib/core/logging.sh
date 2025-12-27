#!/usr/bin/env bash
# lib/core/logging.sh - Logging infrastructure
# sysmaint library
# Copyright (c) 2025 Mohamed Elharery

# Functions:
#   log()                     - Timestamped logging to file and console
#   run()                     - Execute commands with comprehensive logging
#   truncate_log_if_needed()  - Rotate/truncate oversized log files

# This module provides the core logging infrastructure used throughout sysmaint.
# All operations are logged with timestamps, and command execution is tracked
# with full output capture.

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

# Enforce log size limit if configured
truncate_log_if_needed() {
  if ! [[ "$LOG_MAX_SIZE_MB" =~ ^[0-9]+$ ]]; then
    return 0
  fi
  if (( LOG_MAX_SIZE_MB == 0 )); then
    return 0
  fi
  if [[ ! -f "$LOG_FILE" ]]; then
    return 0
  fi
  local size_kb
  size_kb=$(du -k "$LOG_FILE" 2>/dev/null | awk '{print $1}')
  LOG_ORIGINAL_SIZE_KB=${size_kb:-0}
  local limit_kb=$((LOG_MAX_SIZE_MB * 1024))
  if (( size_kb <= limit_kb )); then
    LOG_FINAL_SIZE_KB=$size_kb
    return 0
  fi
  # Preserve tail portion
  local keep_kb
  if ! [[ "$LOG_TAIL_PRESERVE_KB" =~ ^[0-9]+$ ]]; then
    keep_kb=512
  else
    keep_kb=$LOG_TAIL_PRESERVE_KB
  fi
  local keep_bytes=$((keep_kb * 1024))
  # Use tail -c to extract last bytes
  if tail -c "$keep_bytes" "$LOG_FILE" >"${LOG_FILE}.tail" 2>/dev/null; then
    {
      printf '%s\n' "$(date '+%F %T') LOG_TRUNCATED: original_size_kb=${size_kb} limit_kb=${limit_kb} preserved_tail_kb=${keep_kb}";
      cat "${LOG_FILE}.tail"
    } >"${LOG_FILE}.new" 2>/dev/null || true
    mv "${LOG_FILE}.new" "$LOG_FILE" 2>/dev/null || true
    rm -f "${LOG_FILE}.tail" 2>/dev/null || true
    LOG_TRUNCATED=true
    size_kb=$(du -k "$LOG_FILE" 2>/dev/null | awk '{print $1}')
    LOG_FINAL_SIZE_KB=${size_kb:-0}
    log "WARNING: Log truncated to last ${keep_kb}KB (original ${LOG_ORIGINAL_SIZE_KB}KB)."
  fi
}
