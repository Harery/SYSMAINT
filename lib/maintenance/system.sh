#!/usr/bin/env bash
# lib/maintenance/system.sh - System-level maintenance tasks
# sysmaint library

clean_tmp() {
  # Conservative, configurable cleanup of temporary directory before running.
  # Defaults: remove files older than $CLEAR_TMP_AGE_DAYS in $CLEAR_TMP_DIR.
  log "=== Temporary directory cleanup start ==="

  # Safety checks
  if [[ "${CLEAR_TMP:-false}" != "true" ]]; then
    log "--clear-tmp disabled: skipping temporary directory cleanup."
    return 0
  fi

  # Require explicit approval for destructive full-directory wipes.
  # For extra safety, the user must both request force-clearing (CLEAR_TMP_FORCE)
  # and explicitly confirm it (CLEAR_TMP_FORCE_CONFIRMED). In addition, the
  # run must be non-interactive-approved (ASSUME_YES/--yes). This prevents
  # accidental destructive clears from a single accidental flag.
  if [[ "${CLEAR_TMP_FORCE:-false}" == "true" ]]; then
    if [[ "${CLEAR_TMP_FORCE_CONFIRMED:-false}" != "true" ]]; then
      log "ERROR: CLEAR_TMP_FORCE requested but not explicitly confirmed. Use --confirm-clear-tmp-force to confirm."
      return 1
    fi
    if [[ "${ASSUME_YES:-false}" != "true" ]]; then
      log "ERROR: CLEAR_TMP_FORCE requires both --confirm-clear-tmp-force and --yes (ASSUME_YES=true) to proceed."
      return 1
    fi
  fi

  if [[ -z "$CLEAR_TMP_DIR" || "$CLEAR_TMP_DIR" == "/" ]]; then
    log "ERROR: refusing to clean an empty or root directory: '$CLEAR_TMP_DIR'"
    return 1
  fi

  if [[ ! -d "$CLEAR_TMP_DIR" ]]; then
    log "Temporary directory '$CLEAR_TMP_DIR' does not exist; skipping cleanup."
    return 0
  fi

  # If DRY_RUN, only list what would be removed
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    if [[ "${CLEAR_TMP_FORCE:-false}" == "true" ]]; then
      log "DRY_RUN: would remove all contents of $CLEAR_TMP_DIR"
      find "${CLEAR_TMP_DIR:?}" -mindepth 1 -maxdepth 2 -print 2>/dev/null | sed 's/^/DRY_RUN: /' | tee -a "$LOG_FILE"
    else
      log "DRY_RUN: would remove files in $CLEAR_TMP_DIR based on CLEAR_TMP_AGE_DAYS=${CLEAR_TMP_AGE_DAYS}"
      if ! [[ "$CLEAR_TMP_AGE_DAYS" =~ ^[0-9]+$ ]]; then
        log "DRY_RUN: CLEAR_TMP_AGE_DAYS is not a non-negative integer: '$CLEAR_TMP_AGE_DAYS'"
      elif [[ "$CLEAR_TMP_AGE_DAYS" -eq 0 ]]; then
        # files older than today
  find "${CLEAR_TMP_DIR:?}" -mindepth 1 ! -newermt "$(date +%F)" -print 2>/dev/null | sed 's/^/DRY_RUN: /' | tee -a "$LOG_FILE"
      else
  find "${CLEAR_TMP_DIR:?}" -mindepth 1 -mtime +$((CLEAR_TMP_AGE_DAYS-1)) -print 2>/dev/null | sed 's/^/DRY_RUN: /' | tee -a "$LOG_FILE"
      fi
    fi
    log "=== Temporary directory cleanup complete (dry-run) ==="
    return 0
  fi

  # Perform actual removal. Be careful and defensive.
  set +e
  # Validate age param
  if ! [[ "$CLEAR_TMP_AGE_DAYS" =~ ^[0-9]+$ ]]; then
    log "ERROR: CLEAR_TMP_AGE_DAYS must be a non-negative integer. Got: '$CLEAR_TMP_AGE_DAYS'"
    set -e
    return 1
  fi

    if [[ "${CLEAR_TMP_FORCE:-false}" == "true" ]]; then
    log "Removing ALL contents of $CLEAR_TMP_DIR (CLEAR_TMP_FORCE requested)"
    rm -rf -- "${CLEAR_TMP_DIR:?}"/* >>"$LOG_FILE" 2>&1 || true
  elif [[ "$CLEAR_TMP_AGE_DAYS" -eq 0 ]]; then
    log "Removing files in $CLEAR_TMP_DIR older than today (modified before $(date +%F))"
    find "${CLEAR_TMP_DIR:?}" -mindepth 1 ! -newermt "$(date +%F)" -exec rm -rf -- {} + >>"$LOG_FILE" 2>&1 || true
  else
    log "Removing files in $CLEAR_TMP_DIR older than ${CLEAR_TMP_AGE_DAYS} day(s)"
    find "${CLEAR_TMP_DIR:?}" -mindepth 1 -mtime +$((CLEAR_TMP_AGE_DAYS-1)) -exec rm -rf -- {} + >>"$LOG_FILE" 2>&1 || true
  fi
  rc=$?
  set -e

  if [[ $rc -eq 0 ]]; then
    log "Temporary directory cleanup finished (see $LOG_FILE)"
  else
    log "Temporary directory cleanup finished with some errors (see $LOG_FILE)"
  fi
  log "=== Temporary directory cleanup end ==="
  return $rc
}

dns_maintenance() {
  log "=== DNS cache maintenance start ==="
  show_progress 2 "$PROGRESS_MODE" "DNS cache"

  if [[ "${CLEAR_DNS_CACHE:-true}" != "true" ]]; then
    log "--no-clear-dns-cache requested: skipping DNS cache clearing."
    return 0
  fi

  local cleared_any=false

  # 1. systemd-resolved (most common on modern Ubuntu/Debian)
  if command -v resolvectl >/dev/null 2>&1; then
    if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
      if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log "DRY_RUN: would run: resolvectl flush-caches"
      else
        log "Flushing systemd-resolved DNS cache..."
        if resolvectl flush-caches >>"$LOG_FILE" 2>&1; then
          log "systemd-resolved cache flushed successfully"
          cleared_any=true
        else
          log "Failed to flush systemd-resolved cache (see $LOG_FILE)"
        fi
      fi
    else
      log "systemd-resolved not active; skipping resolvectl"
    fi
  fi

  # 2. nscd (Name Service Cache Daemon)
  if command -v nscd >/dev/null 2>&1; then
    if systemctl is-active --quiet nscd 2>/dev/null || pgrep -x nscd >/dev/null 2>&1; then
      if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log "DRY_RUN: would run: nscd -i hosts"
      else
        log "Invalidating nscd hosts cache..."
        if nscd -i hosts >>"$LOG_FILE" 2>&1; then
          log "nscd hosts cache invalidated successfully"
          cleared_any=true
        else
          log "Failed to invalidate nscd cache (see $LOG_FILE)"
        fi
      fi
    else
      log "nscd not running; skipping"
    fi
  fi

  # 3. dnsmasq (local DNS forwarder/cache)
  if command -v dnsmasq >/dev/null 2>&1; then
    if systemctl is-active --quiet dnsmasq 2>/dev/null || pgrep -x dnsmasq >/dev/null 2>&1; then
      if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log "DRY_RUN: would restart dnsmasq to clear cache"
      else
        log "Restarting dnsmasq to clear DNS cache..."
        if systemctl restart dnsmasq >>"$LOG_FILE" 2>&1; then
          log "dnsmasq restarted successfully (cache cleared)"
          cleared_any=true
        else
          log "Failed to restart dnsmasq (see $LOG_FILE)"
        fi
      fi
    else
      log "dnsmasq not running; skipping"
    fi
  fi

  # 4. systemd-networkd (less common but some systems use it)
  if systemctl is-active --quiet systemd-networkd 2>/dev/null; then
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
      log "DRY_RUN: systemd-networkd active; cache flush handled by resolvectl"
    else
      log "systemd-networkd active; DNS cache already handled by resolvectl"
    fi
  fi

  if [[ "$cleared_any" == "false" && "${DRY_RUN:-false}" != "true" ]]; then
    log "No DNS cache services detected or cleared. If you use a custom DNS setup, clear manually."
  fi

  log "=== DNS cache maintenance complete ==="
}

journal_maintenance() {
  if ! command -v journalctl >/dev/null 2>&1; then
    log "journalctl not available; skipping journal maintenance."
    return 0
  fi
  
  log "=== Journal maintenance start ==="
  show_progress 2 "$PROGRESS_MODE" "Journal cleanup"
  
  if [[ "${CLEAR_JOURNAL:-true}" != "true" ]]; then
    log "--no-journal-vacuum requested: skipping journal cleanup."
    return 0
  fi

  local vacuum_time="${JOURNAL_VACUUM_TIME:-7d}"
  local vacuum_size="${JOURNAL_VACUUM_SIZE:-500M}"

  # Vacuum by time
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "DRY_RUN: would run: journalctl --vacuum-time=$vacuum_time"
  else
    log "Cleaning journal logs older than $vacuum_time..."
    if journalctl --vacuum-time="$vacuum_time" >>"$LOG_FILE" 2>&1; then
      log "Journal vacuum by time completed"
    else
      log "Journal vacuum by time failed (see $LOG_FILE)"
    fi
  fi

  # Vacuum by size
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "DRY_RUN: would run: journalctl --vacuum-size=$vacuum_size"
  else
    log "Limiting journal size to $vacuum_size..."
    if journalctl --vacuum-size="$vacuum_size" >>"$LOG_FILE" 2>&1; then
      log "Journal vacuum by size completed"
    else
      log "Journal vacuum by size failed (see $LOG_FILE)"
    fi
  fi

  log "=== Journal maintenance complete ==="
}

thumbnail_maintenance() {
  log "=== Thumbnail cache maintenance start ==="
  show_progress 2 "$PROGRESS_MODE" "Thumbnails"
  
  if [[ "${CLEAR_THUMBNAILS:-true}" != "true" ]]; then
    log "--no-clear-thumbnails requested: skipping thumbnail cache cleanup."
    return 0
  fi

  local thumbnail_dir="$HOME/.cache/thumbnails"
  
  if [[ ! -d "$thumbnail_dir" ]]; then
    log "Thumbnail directory $thumbnail_dir does not exist; skipping."
    return 0
  fi

  local size_before
  size_before=$(du -sb "$thumbnail_dir" 2>/dev/null | awk '{print $1}')
  size_before=${size_before:-0}
  
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "DRY_RUN: would run: rm -rf $thumbnail_dir/*"
    if command -v numfmt >/dev/null 2>&1; then
      log "Thumbnail cache size: $(numfmt --to=iec-i --suffix=B "$size_before" 2>/dev/null || echo "${size_before}B")"
    else
      log "Thumbnail cache size: ${size_before}B"
    fi
  else
    log "Clearing thumbnail cache: $thumbnail_dir"
    if rm -rf "${thumbnail_dir:?}"/* 2>>"$LOG_FILE"; then
      local size_after
      size_after=$(du -sb "$thumbnail_dir" 2>/dev/null | awk '{print $1}')
      size_after=${size_after:-0}
      local freed=$((size_before - size_after))
      THUMBNAIL_FREED_BYTES=$freed
      if command -v numfmt >/dev/null 2>&1; then
        log "Thumbnail cache cleared. Freed: $(numfmt --to=iec-i --suffix=B "$freed" 2>/dev/null || echo "${freed}B")"
      else
        log "Thumbnail cache cleared. Freed: ${freed}B"
      fi
    else
      log "Failed to clear thumbnail cache (see $LOG_FILE)"
    fi
  fi

  log "=== Thumbnail cache maintenance complete ==="
}

browser_cache_phase() {
  if [[ "${BROWSER_CACHE_REPORT:-false}" != "true" && "${BROWSER_CACHE_PURGE:-false}" != "true" ]]; then
    return 0
  fi
  log "=== Browser cache phase start ==="
  local ff_dir="$HOME/.cache/mozilla/firefox" chr_dir="$HOME/.cache/chromium" chrome_dir="$HOME/.cache/google-chrome"
  local sz
  FIREFOX_CACHE_BYTES=0; CHROMIUM_CACHE_BYTES=0; CHROME_CACHE_BYTES=0; BROWSER_CACHE_PURGED_FLAG=false

  if [[ -d "$ff_dir" ]]; then
    sz=$(du -sb "$ff_dir" 2>/dev/null | awk '{print $1}')
    FIREFOX_CACHE_BYTES=${sz:-0}
  fi
  if [[ -d "$chr_dir" ]]; then
    sz=$(du -sb "$chr_dir" 2>/dev/null | awk '{print $1}')
    CHROMIUM_CACHE_BYTES=${sz:-0}
  fi
  if [[ -d "$chrome_dir" ]]; then
    sz=$(du -sb "$chrome_dir" 2>/dev/null | awk '{print $1}')
    CHROME_CACHE_BYTES=${sz:-0}
  fi

  if command -v numfmt >/dev/null 2>&1; then
    log "Browser cache sizes: firefox=$(numfmt --to=iec-i --suffix=B "${FIREFOX_CACHE_BYTES}" 2>/dev/null) chromium=$(numfmt --to=iec-i --suffix=B "${CHROMIUM_CACHE_BYTES}" 2>/dev/null) chrome=$(numfmt --to=iec-i --suffix=B "${CHROME_CACHE_BYTES}" 2>/dev/null)"
  else
    log "Browser cache sizes: firefox=${FIREFOX_CACHE_BYTES}B chromium=${CHROMIUM_CACHE_BYTES}B chrome=${CHROME_CACHE_BYTES}B"
  fi

  if [[ "${BROWSER_CACHE_PURGE:-false}" == "true" ]]; then
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
      [[ -d "$ff_dir" ]] && log "DRY_RUN: would remove contents of $ff_dir"
      [[ -d "$chr_dir" ]] && log "DRY_RUN: would remove contents of $chr_dir"
      [[ -d "$chrome_dir" ]] && log "DRY_RUN: would remove contents of $chrome_dir"
    else
      if [[ -d "$ff_dir" ]]; then rm -rf "${ff_dir:?}"/* >>"$LOG_FILE" 2>&1 || true; BROWSER_CACHE_PURGED_FLAG=true; fi
      if [[ -d "$chr_dir" ]]; then rm -rf "${chr_dir:?}"/* >>"$LOG_FILE" 2>&1 || true; BROWSER_CACHE_PURGED_FLAG=true; fi
      if [[ -d "$chrome_dir" ]]; then rm -rf "${chrome_dir:?}"/* >>"$LOG_FILE" 2>&1 || true; BROWSER_CACHE_PURGED_FLAG=true; fi
      log "Browser cache purge completed"
    fi
  fi
  log "=== Browser cache phase complete ==="
}
