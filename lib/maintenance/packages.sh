#!/usr/bin/env bash
# lib/maintenance/packages.sh - Package management and maintenance
# sysmaint library

wait_for_pkg_managers() {
  log "Validating no conflicting package operations are running..."
  # Wait if apt/apt-get/dpkg/unattended-upgrade is active.
  # We'll temporarily disable the ERR trap for this block and perform an
  # explicit busy-check loop so that pgrep's non-zero exit does not trigger
  # the global ERR handler (which would otherwise log a noisy ERROR line).
  local start_ts now elapsed sleep_time remaining retries busy
  # Allow commands that return non-zero during this check without exiting
  # the script (disable errexit), and also suppress the ERR logging while
  # we observe package-manager activity.
  set +e
  _SM_IGNORED_ERR=1

  start_ts=$(date +%s)
  retries=0
  # Candidate lockfiles to inspect (distro-specific). Tests may override
  # this list via the LOCK_FILES env var (comma-separated) so we can point
  # the check at disposable files during unit tests without requiring root.
  if [[ -n "${LOCK_FILES:-}" ]]; then
    IFS=',' read -r -a lock_files <<<"$LOCK_FILES"
  else
    # Get lock files from abstraction layer
    lock_files=($(pkg_get_lock_files))
  fi

  while :; do
    busy=0

    # 1) Optionally check for active package manager processes (distro-specific).
    # Tests can set ONLY_CHECK_LOCKS=true to skip process scanning and exercise
    # lockfile-only behavior without depending on the host's running processes.
    if [[ "${ONLY_CHECK_LOCKS:-false}" != "true" ]]; then
      # Refined process detection using exact binary names; exclude benign
      # unattended-upgrade-shutdown which can be idle and harmless.
      busy_pids=""
      if command -v pgrep >/dev/null 2>&1; then
        # Get lock processes from abstraction layer (distro-specific)
        local lock_processes
        IFS=' ' read -r -a lock_processes <<< "$(pkg_get_lock_processes)"
        for _name in "${lock_processes[@]}"; do
          this_pids=$(pgrep -x "$_name" 2>/dev/null || true)
          if [[ -n "$this_pids" ]]; then
            busy_pids+=" $this_pids"
          fi
        done
      fi
      if [[ -n "$busy_pids" ]]; then
        filtered_pids=""
        for pid in $busy_pids; do
          cmd=$(ps -o comm= -p "$pid" 2>/dev/null || true)
          if [[ "$cmd" == "unattended-upgrade-shutdown" || -z "$cmd" ]]; then
            continue
          fi
          filtered_pids+=" $pid"
        done
        if [[ -n "$filtered_pids" ]]; then
          busy=1
          busy_procs=$(ps -o comm= -p "$filtered_pids" 2>/dev/null | tr '\n' ' ')
          busy_reason="process (pids: ${filtered_pids:-unknown}, procs: ${busy_procs:-unknown})"
        fi
      fi
    fi

    # 2) Inspect well-known lockfiles. Prefer `fuser`/`lsof` to detect holders. If
    #    those tools are unavailable, treat lockfiles as busy only when they are
    #    recent (to avoid false positives from stale lock files).
    for lf in "${lock_files[@]}"; do
      if [[ -e "$lf" ]]; then
        if [[ "${FORCE_STAT_LOCK_CHECK:-false}" == "true" ]]; then
          # Tests can force the stat-based heuristic even when fuser/lsof are present
          # to simulate lockfile ages without relying on process holders.
          if stat_out=$(stat -c %Y "$lf" 2>/dev/null); then
            now_ts=$(date +%s)
            age=$((now_ts - stat_out))
            if ((age < STALE_LOCK_THRESHOLD)); then
              busy=1
              busy_reason="recent-lockfile:$lf (age ${age}s)"
              break
            fi
          fi
        elif command -v fuser >/dev/null 2>&1; then
          if fuser "$lf" >/dev/null 2>&1; then
            busy=1
            # capture the PIDs for logging (non-fatal)
            lf_pids=$(fuser "$lf" 2>/dev/null | tr '\n' ' ')
            busy_reason="lockfile:$lf (held by pids: ${lf_pids:-unknown})"
            break
          fi
        elif command -v lsof >/dev/null 2>&1; then
          if lsof "$lf" >/dev/null 2>&1; then
            busy=1
            lf_pids=$(lsof -t "$lf" 2>/dev/null | tr '\n' ' ')
            busy_reason="lockfile:$lf (held by pids: ${lf_pids:-unknown})"
            break
          fi
        else
          # Heuristic: consider the lockfile busy only if it was modified recently
          # (e.g., in the last 10 minutes) to avoid false positives from stale files.
          if stat_out=$(stat -c %Y "$lf" 2>/dev/null); then
            now_ts=$(date +%s)
            age=$((now_ts - stat_out))
            if ((age < 600)); then
              busy=1
              busy_reason="recent-lockfile:$lf (age ${age}s)"
              break
            fi
          else
            # If stat fails for some reason, conservatively treat as busy
            busy=1
            busy_reason="lockfile:$lf (exists, unknown owner)"
            break
          fi
        fi
      fi
    done

    if [[ $busy -eq 0 ]]; then
      break
    fi

    ((retries++))
    now=$(date +%s)
    elapsed=$((now - start_ts))

    # Respect a maximum retry count if provided
    if ((WAIT_MAX_RETRIES > 0 && retries >= WAIT_MAX_RETRIES)); then
      log "Max retries (${WAIT_MAX_RETRIES}) reached waiting for package managers; proceeding cautiously. Last reason: ${busy_reason:-unknown}"
      break
    fi

    # Also guard by an absolute timeout
    if ((elapsed >= WAIT_TIMEOUT_SECONDS)); then
      log "Timeout waiting for package managers after ${elapsed}s; proceeding cautiously. Last reason: ${busy_reason:-unknown}"
      break
    fi

    remaining=$((WAIT_TIMEOUT_SECONDS - elapsed))
    # sleep no longer than WAIT_INTERVAL and not more than remaining time
    if ((remaining < WAIT_INTERVAL)); then
      sleep_time=$remaining
    else
      sleep_time=$WAIT_INTERVAL
    fi
    log "Package manager busy; rechecking in ${sleep_time}s... (elapsed ${elapsed}s, retry ${retries})"
    sleep "${sleep_time}"
  done

  # Re-enable ERR logging and restore errexit
  unset _SM_IGNORED_ERR || true
  set -e
}

retry_with_backoff() {
  # Execute a command with exponential backoff retry logic for network failures.
  # Usage: retry_with_backoff <description> <command...>
  # Example: retry_with_backoff "apt update" apt-get update -o Acquire::Retries=3
  
  local description="$1"
  shift
  local cmd=("$@")
  local attempt=1
  local max_attempts="${NETWORK_RETRY_COUNT:-3}"
  local base_delay="${NETWORK_RETRY_BASE_DELAY:-2}"
  local max_delay="${NETWORK_RETRY_MAX_DELAY:-30}"
  local delay
  local exit_code
  
  while [[ $attempt -le $max_attempts ]]; do
    log "Attempting $description (attempt $attempt/$max_attempts)"
    
    # Try to execute the command, capture exit code
    set +e
    "${cmd[@]}"
    exit_code=$?
    set -e
    
    # If successful, return
    if [[ $exit_code -eq 0 ]]; then
      log "$description succeeded on attempt $attempt"
      return 0
    fi
    
    # If this was the last attempt, fail
    if [[ $attempt -ge $max_attempts ]]; then
      log "ERROR: $description failed after $max_attempts attempts (exit code: $exit_code)"
      return $exit_code
    fi
    
    # Calculate exponential backoff delay: base_delay * 2^(attempt-1)
    # Cap at max_delay to prevent excessive waits
    delay=$((base_delay * (1 << (attempt - 1))))
    if [[ $delay -gt $max_delay ]]; then
      delay=$max_delay
    fi
    
    log "WARNING: $description failed (exit code: $exit_code), retrying in ${delay}s..."
    sleep "$delay"
    
    ((attempt++))
  done
  
  return 1
}

fix_broken_if_any() {
  log "Pre-flight: resolving any interrupted or broken states (safe to run)."
  # Use package manager abstraction for fixing broken packages
  pkg_fix_broken || true
}

package_maintenance() {
  log "=== Package maintenance start ==="
  show_progress 3 "$PROGRESS_MODE" "Preparing package manager"
  wait_for_pkg_managers
  # Robust update/upgrade cycle with conservative config handling
  # Capture update output to check signature verification (APT-specific)
  local update_out
  
  # Use retry logic for package update to handle transient network failures
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "DRY_RUN: would run: pkg_update with retry logic"
    update_out="DRY_RUN"
  else
    show_progress 5 "$PROGRESS_MODE" "Refreshing package lists"
    update_out=$(retry_with_backoff "pkg_update" pkg_update 2>&1 | tee -a "$LOG_FILE")
  fi
  
  # Check for GPG signature verification (APT-specific, other package managers handle differently)
  if [[ "$PKG_MANAGER" == "apt" ]]; then
    if echo "$update_out" | grep -qi "NO_PUBKEY"; then
      APT_SIG_STATUS="missing_keys"
    elif echo "$update_out" | grep -qi "signature.*could not be verified\|gpg.*error"; then
      APT_SIG_STATUS="verification_failed"
    elif echo "$update_out" | grep -qi "Signed by\|gpgv"; then
      APT_SIG_STATUS="verified"
    else
      APT_SIG_STATUS="unknown"
    fi
    log "Package signature verification status: $APT_SIG_STATUS"
  fi
  
  # Use retry logic for upgrade commands
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    run pkg_upgrade
    run pkg_full_upgrade
  else
    show_progress 10 "$PROGRESS_MODE" "Applying upgrades"
    retry_with_backoff "pkg_upgrade" pkg_upgrade
    show_progress 10 "$PROGRESS_MODE" "Applying full-upgrade"
    retry_with_backoff "pkg_full_upgrade" pkg_full_upgrade
  fi
  
  # Remove obsolete dependencies and cache clutter
  run pkg_autoremove
  run pkg_autoclean
  log "=== Package maintenance complete ==="
}

apt_maintenance() {
  package_maintenance
}

upgrade_finalize() {
  if [[ "${UPGRADE_PHASE_ENABLED:-false}" != "true" ]]; then
    log "upgrade_finalize: disabled (enable with --upgrade)."
    return 0
  fi
  log "=== Final upgrade phase start ==="
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "DRY_RUN: would run: apt-get -y -o Dpkg::Options::=--force-confold full-upgrade"
    log "=== Final upgrade phase complete (dry-run) ==="
    return 0
  fi
  # Perform a cautious full-upgrade; rely on apt's configured retries earlier
  set +e
  up_out=$(apt-get -y -o Dpkg::Options::=--force-confold full-upgrade 2>&1)
  up_rc=$?
  set -e
  printf '%s\n' "$up_out" | tee -a "$LOG_FILE" >/dev/null
  # Summarize changes
  UPGRADE_CHANGED_COUNT=$(printf '%s\n' "$up_out" | grep -c '^Inst ' || true)
  UPGRADE_REMOVED_COUNT=$(printf '%s\n' "$up_out" | grep -c '^Remv ' || true)
  if [[ $up_rc -eq 0 ]]; then
    log "Final upgrade completed: upgraded=$UPGRADE_CHANGED_COUNT removed=$UPGRADE_REMOVED_COUNT"
  else
    log "WARNING: final upgrade exited with code $up_rc (see $LOG_FILE). Changes: upgraded=$UPGRADE_CHANGED_COUNT removed=$UPGRADE_REMOVED_COUNT"
  fi
  log "=== Final upgrade phase complete ==="
}

orphan_purge_phase() {
  if [[ "${ORPHAN_PURGE_ENABLED:-false}" != "true" ]]; then
    log "orphan_purge_phase: disabled (enable with --orphan-purge or ORPHAN_PURGE_ENABLED=true)."
    return 0
  fi
  log "=== Orphan package purge start ==="
  ORPHAN_PURGED_PACKAGES=()
  # Strategy: if deborphan present use it, else parse apt-get autoremove -s
  local orphan_list=""
  if command -v deborphan >/dev/null 2>&1; then
    orphan_list=$(deborphan 2>/dev/null | tr '\n' ' ' || true)
  else
    # Fallback: parse apt-get autoremove -s lines starting with 'Remv'
    set +e
    sim_out=$(apt-get -s autoremove 2>&1)
    set -e
    orphan_list=$(printf '%s\n' "$sim_out" | awk '/^Remv / {print $2}' | tr '\n' ' ' || true)
  fi
  if [[ -z "$orphan_list" ]]; then
    log "No orphan packages detected."
    log "=== Orphan package purge complete ==="
    return 0
  fi
  # Build array
  declare -a orphans
  while read -r tok; do [[ -n "$tok" ]] && orphans+=("$tok"); done <<<"$orphan_list"
  if (( ${#orphans[@]} == 0 )); then
    log "No orphan packages detected after parsing."
    log "=== Orphan package purge complete ==="
    return 0
  fi
  local would_bytes=0 pkg sz
  for pkg in "${orphans[@]}"; do
    sz=$(dpkg-query -W -f='${Installed-Size}' "$pkg" 2>/dev/null || echo 0)
    ((would_bytes += sz*1024))
  done
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "DRY_RUN: would purge orphan packages: ${orphans[*]}"
    if command -v numfmt >/dev/null 2>&1; then
      log "Estimated space to free: $(numfmt --to=iec-i --suffix=B $would_bytes 2>/dev/null)"
    else
      log "Estimated space to free: ${would_bytes}B"
    fi
    ORPHAN_PURGED_COUNT=${#orphans[@]}
    ORPHAN_PURGED_PACKAGES=("${orphans[@]}")
    log "=== Orphan package purge complete (dry-run) ==="
    return 0
  fi
  local removed=0
  for pkg in "${orphans[@]}"; do
    if apt-get -y purge "$pkg" >>"$LOG_FILE" 2>&1; then
      ((removed++))
      ORPHAN_PURGED_PACKAGES+=("$pkg")
      log "Purged orphan: $pkg"
    else
      log "Failed to purge orphan: $pkg"
    fi
  done
  ORPHAN_PURGED_COUNT=$removed
  log "Orphan purge removed $removed packages."
  log "=== Orphan package purge complete ==="
}
