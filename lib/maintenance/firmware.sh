#!/usr/bin/env bash
# lib/maintenance/firmware.sh - Firmware updates via fwupd
# sysmaint library

firmware_maintenance() {
  # fwupd handles firmware updates for many devices (BIOS, Thunderbolt, etc.)
  if [[ "${NO_FIRMWARE:-false}" == "true" ]]; then
    log "--no-firmware requested: skipping firmware updates."
    _skip_cap "firmware_maintenance" "fwupdmgr(flag)"
    return 0
  fi
  if ! command -v fwupdmgr >/dev/null 2>&1; then
    log "fwupdmgr not installed; skipping firmware maintenance."
    _skip_cap "firmware_maintenance" "fwupdmgr"
    return 0
  fi
  log "=== Firmware maintenance start ==="
  # Refresh metadata
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "DRY_RUN: would run: fwupdmgr refresh --force"
  else
    if fwupdmgr refresh --force >>"$LOG_FILE" 2>&1; then
      log "Firmware metadata refreshed"
    else
      log "Firmware metadata refresh failed (see $LOG_FILE)"
    fi
  fi
  # Get list of available updates
  local updates
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "DRY_RUN: would run: fwupdmgr get-updates"
    updates=$(fwupdmgr get-updates 2>/dev/null | grep -E '^ \*' || true)
  else
    updates=$(fwupdmgr get-updates 2>&1 | tee -a "$LOG_FILE" | grep -E '^ \*' || true)
  fi
  if [[ -z "$updates" ]]; then
    log "No firmware updates available"
  else
    log "Firmware updates available:"
    printf '%s\n' "$updates" | sed 's/^/  /'
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
      log "DRY_RUN: would apply firmware updates"
    else
      if fwupdmgr update -y >>"$LOG_FILE" 2>&1; then
        log "Firmware updates applied (may require reboot)"
      else
        log "Firmware update failed or some updates deferred (see $LOG_FILE)"
      fi
    fi
  fi
  log "=== Firmware maintenance complete ==="
}
