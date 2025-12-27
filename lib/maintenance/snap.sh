#!/usr/bin/env bash
# lib/maintenance/snap.sh - Snap package management
# sysmaint library

snap_maintenance() {
  if ! command -v snap >/dev/null 2>&1; then
    log "Snap not installed; skipping snap tasks."
    _skip_cap "snap_maintenance" "snap"
    return 0
  fi
  log "=== Snap maintenance start ==="
  show_progress 3 "$PROGRESS_MODE" "Preparing Snap"
  # Optionally skip snap refresh/prune
  if [[ "${NO_SNAP:-false}" == "true" ]]; then
    log "--no-snap requested: skipping snap refresh and prune steps."
    return 0
  fi

  # Refresh all snaps

  # Apply snap refresh (will download and install available snap updates)
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "DRY_RUN: would run: snap refresh"
  else
    log "Running: snap refresh (this will download and apply available snap updates)"
    show_progress 8 "$PROGRESS_MODE" "Refreshing snaps"
    run snap refresh || log "snap refresh exited with status $? (see $LOG_FILE)"
  fi

  # Prune old disabled revisions to free disk space
  # Format from `snap list --all`: Name Version Rev Tracking Publisher Notes
  # Be defensive: ensure the revision looks numeric and fall back if --revision
  # isn't supported by the installed snap tooling.
  while read -r name rev notes; do
    if [[ "$notes" == "disabled" ]]; then
      # guard against unexpected revision values
      if ! [[ "$rev" =~ ^[0-9]+$ ]]; then
        log "Skipping snap $name with unexpected revision value: '$rev'"
        continue
      fi

      if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log "DRY_RUN: would remove snap $name revision $rev"
      else
        # Try removing the specific revision; if that fails (older snapd),
        # attempt a fallback removal and log failures.
        if snap remove "$name" --revision="$rev" >>"$LOG_FILE" 2>&1; then
          log "Removed snap $name revision $rev"
        else
          log "snap remove with --revision failed for $name rev $rev; trying fallback"
          if snap remove "$name" >>"$LOG_FILE" 2>&1; then
            log "Removed snap $name (fallback)"
          else
            log "Failed to remove snap $name revision $rev (see $LOG_FILE)"
          fi
        fi
      fi
    fi
  done < <(snap list --all 2>/dev/null | awk 'NR>1 {print $1, $3, $NF}')
  log "=== Snap maintenance complete ==="
}

snap_cleanup_old() {
  if ! command -v snap >/dev/null 2>&1; then
    _skip_cap "snap_cleanup_old" "snap"
    return 0
  fi
  if [[ "${NO_SNAP:-false}" == "true" ]]; then
    return 0
  fi
  if [[ "${SNAP_CLEAN_OLD:-false}" != "true" ]]; then
    log "snap_cleanup_old: flag disabled (--no-snap-clean-old or env). Skipping."
    return 0
  fi
  log "=== Snap old revision cleanup start ==="

  # Safety: skip if other snap operations are currently 'Doing'
  local busy_changes
  busy_changes=$(snap changes 2>/dev/null | awk '/Doing/ {print $1}' || true)
  if [[ -n "$busy_changes" ]]; then
    log "Snap changes in progress (IDs: $busy_changes); deferring old revision cleanup"
    log "=== Snap old revision cleanup deferred ==="
    return 0
  fi

  local removed=0 would_remove=0
  # List disabled revisions
  # Format: Name Version Rev Tracking Publisher Notes
  while read -r name rev notes; do
    if [[ "$notes" == "disabled" ]]; then
      if ! [[ "$rev" =~ ^[0-9]+$ ]]; then
        log "Skipping snap $name with unexpected revision value: '$rev'"
        continue
      fi
      if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log "DRY_RUN: would remove snap $name revision $rev"
        ((would_remove++))
      else
        if snap remove "$name" --revision="$rev" >>"$LOG_FILE" 2>&1; then
          log "Removed snap $name revision $rev"
          ((removed++))
        else
          log "snap remove --revision failed for $name rev $rev; attempting fallback"
          if snap remove "$name" >>"$LOG_FILE" 2>&1; then
            log "Removed snap $name (fallback)"
            ((removed++))
          else
            log "Failed to remove snap $name revision $rev (see $LOG_FILE)"
          fi
        fi
      fi
    fi
  done < <(snap list --all 2>/dev/null | awk 'NR>1 {print $1, $3, $NF}')

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    SNAP_OLD_REMOVED_COUNT=$would_remove
    log "Snap old revision cleanup (dry-run) would remove: $would_remove"
  else
    SNAP_OLD_REMOVED_COUNT=$removed
    log "Snap old revision cleanup removed: $removed"
  fi
  log "=== Snap old revision cleanup complete ==="
}

snap_clear_cache() {
  if ! command -v snap >/dev/null 2>&1; then
    _skip_cap "snap_clear_cache" "snap"
    return 0
  fi
  if [[ "${NO_SNAP:-false}" == "true" ]]; then
    return 0
  fi
  if [[ "${SNAP_CLEAR_CACHE:-false}" != "true" ]]; then
    log "snap_clear_cache: flag disabled (--no-snap-clear-cache or env). Skipping."
    return 0
  fi
  local cache_dir="/var/lib/snapd/cache"
  if [[ ! -d "$cache_dir" ]]; then
    log "Snap cache directory not found ($cache_dir); skipping."
    return 0
  fi
  log "=== Snap cache clear start ==="
  local size_before size_after freed
  size_before=$(du -sb "$cache_dir" 2>/dev/null | awk '{print $1}')
  size_before=${size_before:-0}
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "DRY_RUN: would remove contents of $cache_dir"
    if command -v numfmt >/dev/null 2>&1; then
      log "Snap cache size: $(numfmt --to=iec-i --suffix=B "$size_before" 2>/dev/null || echo "${size_before}B")"
    else
      log "Snap cache size: ${size_before}B"
    fi
    SNAP_CACHE_CLEARED_BYTES=$size_before
    log "=== Snap cache clear complete (dry-run) ==="
    return 0
  fi
  if rm -rf "${cache_dir:?}"/* >>"$LOG_FILE" 2>&1; then
    size_after=$(du -sb "$cache_dir" 2>/dev/null | awk '{print $1}')
    size_after=${size_after:-0}
    freed=$((size_before - size_after))
    SNAP_CACHE_CLEARED_BYTES=$freed
    if command -v numfmt >/dev/null 2>&1; then
      log "Snap cache cleared. Freed: $(numfmt --to=iec-i --suffix=B "$freed" 2>/dev/null || echo "${freed}B")"
    else
      log "Snap cache cleared. Freed: ${freed}B"
    fi
  else
    log "Failed to clear snap cache (see $LOG_FILE)"
  fi
  log "=== Snap cache clear complete ==="
}
