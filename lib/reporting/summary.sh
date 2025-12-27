#!/usr/bin/bash
# lib/reporting/summary.sh
# stable: Summary report generation

print_summary() {
  log "=== Maintenance summary ==="

  # Helper: escape a string for JSON
  escape_json() {
    # Escape backslashes and double quotes, preserve newlines as \n
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e ':a;N;$!ba;s/\n/\\n/g'
  }

  # Helper: convert a bash array (name passed) into a JSON array string
  array_to_json() {
    local -n _arr=$1
    local out='['
    local sep=''
    local v esc
    for v in "${_arr[@]}"; do
      esc=$(escape_json "$v")
      out+="$sep\"$esc\""
      sep=','
    done
    out+=']'
    printf '%s' "$out"
  }

  # Repositories summary
  local ok_count mismatch_count fail_count
  ok_count=${#REPO_OK[@]}
  mismatch_count=${#REPO_MISMATCH[@]}
  fail_count=${#REPO_FAIL[@]}

  printf '\n' | tee -a "$LOG_FILE"
  printf 'Repository summary:\n' | tee -a "$LOG_FILE"
  printf '  OK: %d\n' "$ok_count" | tee -a "$LOG_FILE"
  printf '  Mismatch: %d\n' "$mismatch_count" | tee -a "$LOG_FILE"
  printf '  Unreachable/Missing: %d\n' "$fail_count" | tee -a "$LOG_FILE"

  if ((mismatch_count > 0)); then
    printf '  Mismatched entries (uri|suite):\n' | tee -a "$LOG_FILE"
    for e in "${REPO_MISMATCH[@]}"; do printf '    %s\n' "$e" | tee -a "$LOG_FILE"; done
  fi
  if ((fail_count > 0)); then
    printf '  Unreachable entries (uri|suite):\n' | tee -a "$LOG_FILE"
    for e in "${REPO_FAIL[@]}"; do printf '    %s\n' "$e" | tee -a "$LOG_FILE"; done
  fi

  # Missing public keys summary (NO_PUBKEY) detected during apt-get update
  local mpk_count
  mpk_count=${#MISSING_PUBKEYS[@]}
  printf '\n' | tee -a "$LOG_FILE"
  printf 'Missing repository public keys (NO_PUBKEY): %d\n' "$mpk_count" | tee -a "$LOG_FILE"
  if ((mpk_count > 0)); then
    for k in "${MISSING_PUBKEYS[@]}"; do
      printf '    %s\n' "$k" | tee -a "$LOG_FILE"
    done
  elif [[ "${DRY_RUN:-false}" == "true" && "${NO_PUBKEY_SKIPPED:-false}" == "true" ]]; then
    printf '  (Detection skipped under --dry-run)\n' | tee -a "$LOG_FILE"
  fi

  # Kernel summary
  local kcount
  kcount=${#KERNEL_UPGRADE_LIST[@]}
  printf '\n' | tee -a "$LOG_FILE"
  printf 'Kernel summary:\n' | tee -a "$LOG_FILE"
  printf '  Current kernel: %s\n' "$(uname -r)" | tee -a "$LOG_FILE"
  printf '  Kernel upgradable packages: %d\n' "$kcount" | tee -a "$LOG_FILE"
  if ((kcount > 0)); then
    for k in "${KERNEL_UPGRADE_LIST[@]}"; do printf '    %s\n' "$k" | tee -a "$LOG_FILE"; done
  fi
  printf '  Reboot required: %s\n' "${SUMMARY_REBOOT_REQUIRED}" | tee -a "$LOG_FILE"

  # APT signature verification summary
  printf '\n' | tee -a "$LOG_FILE"
  printf 'APT signature verification: %s\n' "$APT_SIG_STATUS" | tee -a "$LOG_FILE"

  # Failed services summary
  local fs_count
  fs_count=${#FAILED_SERVICES[@]}
  if ((fs_count > 0)); then
    printf '\n' | tee -a "$LOG_FILE"
    printf 'Failed systemd services: %d\n' "$fs_count" | tee -a "$LOG_FILE"
    for s in "${FAILED_SERVICES[@]}"; do
      printf '    %s\n' "$s" | tee -a "$LOG_FILE"
    done
  fi

  # Disk usage summary
  if [[ -n "$DISK_BEFORE" && -n "$DISK_AFTER" ]]; then
    printf '\n' | tee -a "$LOG_FILE"
    printf 'Disk usage (root filesystem):\n' | tee -a "$LOG_FILE"
    printf '  Before: %s KB\n' "$DISK_BEFORE" | tee -a "$LOG_FILE"
    printf '  After:  %s KB\n' "$DISK_AFTER" | tee -a "$LOG_FILE"
    if ((DISK_SAVED_KB > 0)); then
      printf '  Freed:  %s KB (%.2f MB)\n' "$DISK_SAVED_KB" "$(echo "scale=2; $DISK_SAVED_KB / 1024" | bc)" | tee -a "$LOG_FILE"
    elif ((DISK_SAVED_KB < 0)); then
      printf '  Used:   %s KB (%.2f MB)\n' "$((0 - DISK_SAVED_KB))" "$(echo "scale=2; $((-DISK_SAVED_KB)) / 1024" | bc)" | tee -a "$LOG_FILE"
    else
      printf '  No change\n' | tee -a "$LOG_FILE"
    fi
    
    # Per-phase disk deltas
    set +u
    if declare -p PHASE_DISK_DELTAS >/dev/null 2>&1 && (( ${#PHASE_DISK_DELTAS[@]} > 0 )); then
      printf '  Per-phase disk deltas (freed=positive, used=negative):\n' | tee -a "$LOG_FILE"
      for phase in "${!PHASE_DISK_DELTAS[@]}"; do
        local delta=${PHASE_DISK_DELTAS[$phase]}
        if ((delta > 0)); then
          printf '    %s: +%s KB (freed)\n' "$phase" "$delta" | tee -a "$LOG_FILE"
        elif ((delta < 0)); then
          printf '    %s: %s KB (used)\n' "$phase" "$delta" | tee -a "$LOG_FILE"
        else
          printf '    %s: 0 KB (no change)\n' "$phase" | tee -a "$LOG_FILE"
        fi
      done
    fi
    set -u
  fi
  
  # Additional metrics summary
  if ((THUMBNAIL_FREED_BYTES > 0)); then
    printf '\n' | tee -a "$LOG_FILE"
    if command -v numfmt >/dev/null 2>&1; then
      printf 'Thumbnail cache freed: %s\n' "$(numfmt --to=iec-i --suffix=B "$THUMBNAIL_FREED_BYTES" 2>/dev/null || echo "${THUMBNAIL_FREED_BYTES}B")" | tee -a "$LOG_FILE"
    else
      printf 'Thumbnail cache freed: %s bytes\n' "$THUMBNAIL_FREED_BYTES" | tee -a "$LOG_FILE"
    fi
  fi
  if ((SNAP_OLD_REMOVED_COUNT > 0)); then
    printf 'Snap old revisions removed: %d\n' "$SNAP_OLD_REMOVED_COUNT" | tee -a "$LOG_FILE"
  fi
  if ((SNAP_CACHE_CLEARED_BYTES > 0)); then
    if command -v numfmt >/dev/null 2>&1; then
      printf 'Snap cache freed: %s\n' "$(numfmt --to=iec-i --suffix=B "$SNAP_CACHE_CLEARED_BYTES" 2>/dev/null || echo "${SNAP_CACHE_CLEARED_BYTES}B")" | tee -a "$LOG_FILE"
    else
      printf 'Snap cache freed: %s bytes\n' "$SNAP_CACHE_CLEARED_BYTES" | tee -a "$LOG_FILE"
    fi
  fi
  if ((CRASH_FREED_BYTES > 0)); then
    if command -v numfmt >/dev/null 2>&1; then
      printf 'Crash dump freed: %s\n' "$(numfmt --to=iec-i --suffix=B "$CRASH_FREED_BYTES" 2>/dev/null || echo "${CRASH_FREED_BYTES}B")" | tee -a "$LOG_FILE"
    else
      printf 'Crash dump freed: %s bytes\n' "$CRASH_FREED_BYTES" | tee -a "$LOG_FILE"
    fi
  fi
  if ((FSTRIM_TOTAL_TRIMMED > 0)); then
    if command -v numfmt >/dev/null 2>&1; then
      printf 'fstrim total freed: %s\n' "$(numfmt --to=iec-i --suffix=B "$FSTRIM_TOTAL_TRIMMED" 2>/dev/null || echo "${FSTRIM_TOTAL_TRIMMED}B")" | tee -a "$LOG_FILE"
    else
      printf 'fstrim total freed: %s bytes\n' "$FSTRIM_TOTAL_TRIMMED" | tee -a "$LOG_FILE"
    fi
  fi
  if [[ "${PURGE_OLD_KERNELS:-false}" == "true" ]]; then
    printf 'Kernel purge kept newest: %s (removed %s)\n' "$KEEP_KERNELS" "$KERNELS_REMOVED_COUNT" | tee -a "$LOG_FILE"
  fi
  if [[ "${ORPHAN_PURGE_ENABLED:-false}" == "true" && ${ORPHAN_PURGED_COUNT} -gt 0 ]]; then
    printf 'Orphan packages purged: %s\n' "$ORPHAN_PURGED_COUNT" | tee -a "$LOG_FILE"
  fi
  
  if [[ "${NO_FLATPAK:-false}" != "true" && -n "$FLATPAK_SCOPE_APPLIED" ]]; then
    printf 'Flatpak scope applied: %s\n' "$FLATPAK_SCOPE_APPLIED" | tee -a "$LOG_FILE"
  fi

  printf '\n' | tee -a "$LOG_FILE"
  log "=== End summary ==="

  # Emit JSON summary if requested
  if [[ "${JSON_SUMMARY:-false}" == "true" && "${_JSON_WRITTEN:-false}" != "true" ]]; then
    _JSON_WRITTEN=true
    JSON_FILE="$LOG_DIR/sysmaint_${RUN_ID}.json"
    timestamp=$(date --iso-8601=seconds)
    # Ensure phase estimates are loaded even if adaptive mode wasn't enabled
    if declare -f load_phase_estimates >/dev/null 2>&1; then
      if [[ -z "${PHASE_EST_EMA[clean_tmp]:-}" ]]; then
        load_phase_estimates || true
      fi
    fi
    repo_ok_json=$(array_to_json REPO_OK)
    repo_mismatch_json=$(array_to_json REPO_MISMATCH)
    repo_fail_json=$(array_to_json REPO_FAIL)
    kernel_up_json=$(array_to_json KERNEL_UPGRADE_LIST)
    missing_keys_json=$(array_to_json MISSING_PUBKEYS)
    
    # Write JSON with error suppression to avoid ERR trap during JSON generation
    set +e
    trap - ERR
    {
      printf '{\n'
      printf '  "schema_version": "1.0",\n'
      printf '  "script_version": "%s",\n' "$SCRIPT_VERSION"
      # Compute log file checksum if available
      local lf_hash="unavailable"
      if command -v sha256sum >/dev/null 2>&1 && [[ -f "$LOG_FILE" ]]; then
        lf_hash=$(sha256sum "$LOG_FILE" 2>/dev/null | awk '{print $1}' || echo "unavailable")
      fi
      printf '  "log_file_sha256": "%s",\n' "${lf_hash}"
      printf '  "run_id": "%s",\n' "$(escape_json "$RUN_ID")"
      printf '  "timestamp": "%s",\n' "$timestamp"
  printf '  "dry_run_mode": %s,\n' "${DRY_RUN}"
      printf '  "repos": {"ok": %s, "mismatch": %s, "unreachable": %s},\n' "$repo_ok_json" "$repo_mismatch_json" "$repo_fail_json"
      printf '  "kernel": {"current": "%s", "upgradable": %s},\n' "$(escape_json "$(uname -r)")" "$kernel_up_json"
      printf '  "missing_pubkeys": %s,\n' "$missing_keys_json"
      failed_services_json=$(array_to_json FAILED_SERVICES)
      printf '  "failed_services": %s,\n' "$failed_services_json"
      # Add phase timings
      printf '  "phase_timings": {\n'
      local phase_keys=()
      for key in "${!PHASE_TIMINGS[@]}"; do
        [[ "$key" == *_duration ]] && phase_keys+=("$key")
      done
      local idx=0 total=${#phase_keys[@]}
      for key in "${phase_keys[@]}"; do
        ((idx++))
        local phase_name="${key%_duration}"
        local sep=","
        [[ $idx -eq $total ]] && sep=""
        printf '    "%s": %s%s\n' "$phase_name" "${PHASE_TIMINGS[$key]}" "$sep"
      done
      printf '  },\n'
      # Disk usage
      printf '  "disk_usage": {"before_kb": %s, "after_kb": %s, "saved_kb": %s},\n' "${DISK_BEFORE:-0}" "${DISK_AFTER:-0}" "${DISK_SAVED_KB}"
      # Per-phase disk deltas
      printf '  "phase_disk_deltas_kb": {\n'
      set +u
      if declare -p PHASE_DISK_DELTAS >/dev/null 2>&1 && (( ${#PHASE_DISK_DELTAS[@]} > 0 )); then
        local delta_keys=()
        for key in "${!PHASE_DISK_DELTAS[@]}"; do
          delta_keys+=("$key")
        done
        local didx=0 dtotal=${#delta_keys[@]}
        for key in "${delta_keys[@]}"; do
          ((didx++))
          local dsep=","; [[ $didx -eq $dtotal ]] && dsep=""
          printf '    "%s": %s%s\n' "$key" "${PHASE_DISK_DELTAS[$key]}" "$dsep"
        done
      fi
      set -u
      printf '  },\n'
      # EMA phase estimates (seconds)
      printf '  "phase_estimates_ema": {\n'
      local ekeys=()
      for key in "${!PHASE_EST_EMA[@]}"; do
        ekeys+=("$key")
      done
      local eidx=0 etotal=${#ekeys[@]}
      for key in "${ekeys[@]}"; do
        ((eidx++))
        local esep=","; [[ $eidx -eq $etotal ]] && esep=""
        printf '    "%s": %s%s\n' "$key" "${PHASE_EST_EMA[$key]}" "$esep"
      done
      printf '  },\n'
      # Flatpak and thumbnail metrics
      printf '  "flatpak_scope_applied": "%s",\n' "$FLATPAK_SCOPE_APPLIED"
      printf '  "thumbnail_freed_bytes": %s,\n' "${THUMBNAIL_FREED_BYTES}"
      printf '  "snap_old_revisions_removed": %s,\n' "${SNAP_OLD_REMOVED_COUNT}"
      printf '  "snap_cache_cleared_bytes": %s,\n' "${SNAP_CACHE_CLEARED_BYTES}"
  printf '  "crash_freed_bytes": %s,\n' "${CRASH_FREED_BYTES}"
  trimmed_fs_json=$(array_to_json TRIMMED_FILESYSTEMS)
  printf '  "fstrim_total_trimmed_bytes": %s,\n' "${FSTRIM_TOTAL_TRIMMED}"
  printf '  "trimmed_filesystems": %s,\n' "$trimmed_fs_json"
      printf '  "final_upgrade_enabled": %s,\n' "${UPGRADE_PHASE_ENABLED}"
      printf '  "final_upgrade_upgraded_count": %s,\n' "${UPGRADE_CHANGED_COUNT}"
      printf '  "final_upgrade_removed_count": %s,\n' "${UPGRADE_REMOVED_COUNT}"
  printf '  "drop_caches_enabled": %s,\n' "${DROP_CACHES_ENABLED}"
  printf '  "mem_available_before_kb": %s,\n' "${MEM_BEFORE_KB}"
  printf '  "mem_available_after_kb": %s,\n' "${MEM_AFTER_KB}"
  printf '  "swap_free_before_kb": %s,\n' "${SWAP_BEFORE_KB}"
  printf '  "swap_free_after_kb": %s,\n' "${SWAP_AFTER_KB}"
  printf '  "auto_mode": %s,\n' "${AUTO_MODE}"
  printf '  "auto_reboot_delay_seconds": %s,\n' "${AUTO_REBOOT_DELAY}"
  printf '  "journal_vacuum_time": "%s",\n' "$(escape_json "${JOURNAL_VACUUM_TIME}")"
  printf '  "journal_vacuum_size": "%s",\n' "$(escape_json "${JOURNAL_VACUUM_SIZE}")"
    printf '  "kernel_purge_enabled": %s,\n' "${PURGE_OLD_KERNELS}"
    printf '  "keep_kernels": %s,\n' "${KEEP_KERNELS}"
    printf '  "kernels_removed_count": %s,\n' "${KERNELS_REMOVED_COUNT}"
    printf '  "update_grub_enabled": %s,\n' "${UPDATE_GRUB_ENABLED}"
    printf '  "update_grub_ran": %s,\n' "${UPDATE_GRUB_RAN}"
    printf '  "update_grub_success": %s,\n' "${UPDATE_GRUB_SUCCESS}"
    orphan_json=$(array_to_json ORPHAN_PURGED_PACKAGES)
    printf '  "orphan_purge_enabled": %s,\n' "${ORPHAN_PURGE_ENABLED}"
    printf '  "orphan_purged_count": %s,\n' "${ORPHAN_PURGED_COUNT}"
    printf '  "orphan_purged_packages": %s,\n' "$orphan_json"
  printf '  "color_mode": "%s",\n' "$(escape_json "$COLOR_MODE")"
  printf '  "log_truncated": %s,\n' "${LOG_TRUNCATED}"
  printf '  "log_original_size_kb": %s,\n' "${LOG_ORIGINAL_SIZE_KB}"
  printf '  "log_final_size_kb": %s,\n' "${LOG_FINAL_SIZE_KB}"
  zombies_json=$(array_to_json ZOMBIE_PROCESSES)
  printf '  "zombie_check_enabled": %s,\n' "${CHECK_ZOMBIES}"
  printf '  "zombie_count": %s,\n' "${ZOMBIE_COUNT}"
  printf '  "zombie_processes": %s,\n' "$zombies_json"
  sudoers_d_json=$(array_to_json SUDOERS_D_ISSUES)
  printf '  "security_audit_enabled": %s,\n' "${SECURITY_AUDIT_ENABLED}"
  printf '  "shadow_perms_ok": "%s",\n' "$(escape_json "${SHADOW_PERMS_OK}")"
  printf '  "gshadow_perms_ok": "%s",\n' "$(escape_json "${GSHADOW_PERMS_OK}")"
  printf '  "sudoers_perms_ok": "%s",\n' "$(escape_json "${SUDOERS_PERMS_OK}")"
  printf '  "sudoers_d_issues": %s,\n' "$sudoers_d_json"
  printf '  "browser_cache_report": %s,\n' "${BROWSER_CACHE_REPORT}"
  printf '  "browser_cache_purge": %s,\n' "${BROWSER_CACHE_PURGE}"
  printf '  "firefox_cache_bytes": %s,\n' "${FIREFOX_CACHE_BYTES}"
  printf '  "chromium_cache_bytes": %s,\n' "${CHROMIUM_CACHE_BYTES}"
  printf '  "chrome_cache_bytes": %s,\n' "${CHROME_CACHE_BYTES}"
  printf '  "browser_cache_purged": %s,\n' "${BROWSER_CACHE_PURGED_FLAG}"
      if [[ "${SIMULATE_UPGRADE:-false}" == "true" || -n "${SIMULATED_UPGRADE_COUNT:-}" ]]; then
        sim_up=${SIMULATED_UPGRADE_COUNT:-0}
        sim_rem=${SIMULATED_REMOVE_COUNT:-0}
        sim_conf=${SIMULATED_CONFIGURE_COUNT:-0}
        sim_path=$(escape_json "$LOG_DIR/simulate_${RUN_ID}.txt")
        printf '  "simulation": {"upgrade": %d, "remove": %d, "configure": %d, "output_file": "%s"},\n' "$sim_up" "$sim_rem" "$sim_conf" "$sim_path"
      fi
  printf '  "apt_signature_status": "%s",\n' "$APT_SIG_STATUS"
  printf '  "reboot_required": %s,\n' "${SUMMARY_REBOOT_REQUIRED}"
  printf '  "reboot_recommended": %s,\n' "${SUMMARY_REBOOT_REQUIRED}"
  caps_av_json=$(array_to_json CAPABILITIES_AVAILABLE)
  caps_un_json=$(array_to_json CAPABILITIES_UNAVAILABLE)
  printf '  "capabilities": {"available": %s, "unavailable": %s},\n' "$caps_av_json" "$caps_un_json"
  skipped_caps_json=$(array_to_json SKIPPED_CAPABILITIES)
  printf '  "skipped_capabilities": %s,\n' "$skipped_caps_json"
  printf '  "desktop_mode": "%s",\n' "$(escape_json "$DESKTOP_MODE")"
  printf '  "desktop_guard_enabled": %s,\n' "${DESKTOP_GUARD_ENABLED}"
  printf '  "os_description": "%s",\n' "$(escape_json "$OS_DESCRIPTION")"
  printf '  "hostname": "%s",\n' "$(escape_json "$(hostname 2>/dev/null || echo 'unknown')")"
  printf '  "uptime_seconds": %s,\n' "${UPTIME_SECONDS}"
  printf '  "package_count": %s,\n' "${PACKAGE_COUNT}"
  printf '  "mem_total_kb": %s,\n' "${MEM_TOTAL_KB}"
  printf '  "mem_available_start_kb": %s,\n' "${MEM_AVAILABLE_KB_START}"
  printf '  "swap_total_kb": %s,\n' "${SWAP_TOTAL_KB}"
  printf '  "disk_root_total_kb": %s,\n' "${DISK_ROOT_TOTAL_KB}"
  printf '  "log_file": "%s",\n' "$(escape_json "$LOG_FILE")"
  printf '  "checksum_sha256": "PLACEHOLDER"\n'
      printf '}\n'
    } >"$JSON_FILE" 2>>"$LOG_FILE"
    # Compute checksum over placeholder version then replace placeholder
    if command -v sha256sum >/dev/null 2>&1; then
      sum=$(sha256sum "$JSON_FILE" | awk '{print $1}' || echo "unavailable")
      sed -i "s/\"checksum_sha256\": \"PLACEHOLDER\"/\"checksum_sha256\": \"$sum\"/" "$JSON_FILE" 2>>"$LOG_FILE" || true
    else
      sum="unavailable"
    fi
    set -e
    trap on_err ERR
    # Validate JSON write
    if [[ -s "$JSON_FILE" ]]; then
      log "JSON summary written to $JSON_FILE (checksum=$sum)"
    else
      log "ERROR: JSON summary not written (file missing or empty): $JSON_FILE"
    fi
  fi
  if [[ "${JSON_SUMMARY:-false}" == "true" && "${_JSON_WRITTEN:-false}" == "true" ]]; then
    log "DEBUG: JSON summary generation skipped due to _JSON_WRITTEN guard"
  fi
}
