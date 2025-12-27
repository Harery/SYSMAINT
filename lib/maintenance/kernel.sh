#!/usr/bin/env bash
# lib/maintenance/kernel.sh - Kernel management and purging
# sysmaint library

kernel_purge_phase() {
  if [[ "${PURGE_OLD_KERNELS:-false}" != "true" ]]; then
    log "kernel_purge_phase: disabled (enable with --purge-kernels or PURGE_OLD_KERNELS=true)."
    return 0
  fi
  log "=== Kernel purge phase start (keep ${KEEP_KERNELS}) ==="
  # Determine running kernel image pattern
  local running_kernel keep_n
  running_kernel=$(uname -r)
  keep_n=${KEEP_KERNELS:-2}
  if ! [[ "$keep_n" =~ ^[0-9]+$ ]]; then keep_n=2; fi
  # Build a list of all installed kernel component packages (image, headers, modules, extra),
  # derive their version suffixes, and decide based on versions rather than only image presence.
  local all_pkgs
  all_pkgs=$(dpkg -l 'linux-*' 2>/dev/null | awk '/^ii/ {print $2}' | grep -E '^linux-(image|image-unsigned|headers|modules|modules-extra)-[0-9]') || true
  if [[ -z "$all_pkgs" ]]; then
    log "No kernel component packages found; skipping purge."
    return 0
  fi
  declare -A uniq_versions
  declare -a all_versions=()
  while IFS= read -r _pkg; do
    [[ -n "$_pkg" ]] || continue
    # Extract the kernel version suffix by stripping known prefixes explicitly.
    # Avoid generic globs like ${var#linux-*-} which can leave stray prefixes like 'extra-'.
    local v=""
    case "$_pkg" in
      linux-image-unsigned-*) v=${_pkg#linux-image-unsigned-} ;;
      linux-modules-extra-*)  v=${_pkg#linux-modules-extra-}  ;;
      linux-modules-*)        v=${_pkg#linux-modules-}        ;;
      linux-image-*)          v=${_pkg#linux-image-}          ;;
      linux-headers-*)        v=${_pkg#linux-headers-}        ;;
      *) v="" ;;
    esac
    [[ -n "$v" ]] || continue
    if [[ -z "${uniq_versions[$v]:-}" ]]; then
      uniq_versions[$v]=1
      all_versions+=("$v")
    fi
  done <<<"$all_pkgs"
  # Sort versions descending using dpkg --compare-versions
  for ((i=0; i<${#all_versions[@]}; i++)); do
    for ((j=i+1; j<${#all_versions[@]}; j++)); do
      if dpkg --compare-versions "${all_versions[j]}" gt "${all_versions[i]}"; then
        tmp=${all_versions[i]}; all_versions[i]=${all_versions[j]}; all_versions[j]=$tmp
      fi
    done
  done
  # Keep top keep_n versions plus the running kernel version explicitly
  declare -A keep_versions
  local idx=0
  for v in "${all_versions[@]}"; do
    if (( idx < keep_n )); then keep_versions["$v"]=1; fi
    ((idx++))
  done
  keep_versions["$running_kernel"]=1
  # Determine removable versions
  local -A rem_versions=()
  for v in "${all_versions[@]}"; do
    if [[ -z "${keep_versions[$v]:-}" ]]; then rem_versions["$v"]=1; fi
  done
  if (( ${#rem_versions[@]} == 0 )); then
    log "No old kernels eligible for removal (keep=${keep_n}, running=${running_kernel})."
    return 0
  fi
  # Expand to concrete package names for those versions, only if installed
  local -a remove_list=()
  for ver in "${!rem_versions[@]}"; do
    for cand in \
      "linux-image-${ver}" \
      "linux-image-unsigned-${ver}" \
      "linux-headers-${ver}" \
      "linux-modules-${ver}" \
      "linux-modules-extra-${ver}"; do
      if dpkg -l "$cand" 2>/dev/null | awk '/^ii/ {exit 0} END{exit 1}'; then
        remove_list+=("$cand")
      fi
    done
  done
  local would_bytes=0
  # Estimate space by summing installed size (dpkg-query -W -f '${Installed-Size}') *1024
  for pkg in "${remove_list[@]}"; do
    sz=$(dpkg-query -W -f='${Installed-Size}' "$pkg" 2>/dev/null || echo 0)
    ((would_bytes += sz*1024))
  done
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "DRY_RUN: would purge kernels: ${remove_list[*]}"
    if command -v numfmt >/dev/null 2>&1; then
      log "Estimated space to free: $(numfmt --to=iec-i --suffix=B $would_bytes 2>/dev/null)"
    else
      log "Estimated space to free: ${would_bytes}B"
    fi
    KERNELS_REMOVED_COUNT=${#remove_list[@]}
    log "=== Kernel purge phase complete (dry-run) ==="
    return 0
  fi
  local removed=0
  for pkg in "${remove_list[@]}"; do
    if apt-get -y purge "$pkg" >>"$LOG_FILE" 2>&1; then
      ((removed++))
      log "Purged kernel package: $pkg"
    else
      log "Failed to purge $pkg"
    fi
  done
  KERNELS_REMOVED_COUNT=$removed
  log "Kernel purge removed $removed packages (keep=$keep_n running=$running_kernel)."
  log "=== Kernel purge phase complete ==="
}

post_kernel_finalize() {
  if [[ "${PURGE_OLD_KERNELS:-false}" != "true" ]]; then
    log "post_kernel_finalize: skipped (kernel purge not enabled)."
    return 0
  fi
  log "=== Post-kernel finalization start ==="
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "DRY_RUN: would run: update-initramfs -c -k $(uname -r) (or -u for all installed kernels)"
    log "DRY_RUN: would run: updatedb"
    if [[ "${UPDATE_GRUB_ENABLED:-false}" == "true" ]]; then
      log "DRY_RUN: would run: update-grub (explicit grub configuration refresh)"
    fi
    log "=== Post-kernel finalization complete (dry-run) ==="
    return 0
  fi
  # Regenerate initramfs for current kernel to ensure consistency
  if command -v update-initramfs >/dev/null 2>&1; then
    if update-initramfs -u -k "$(uname -r)" >>"$LOG_FILE" 2>&1; then
      log "Initramfs updated for kernel $(uname -r)"
    else
      log "WARNING: initramfs update failed (see $LOG_FILE)"
    fi
  else
    log "update-initramfs not found; skipping initramfs regeneration"
  fi
  # Refresh file location database (locate/updatedb) if available
  if command -v updatedb >/dev/null 2>&1; then
    if updatedb >>"$LOG_FILE" 2>&1; then
      log "updatedb completed"
    else
      log "WARNING: updatedb failed (see $LOG_FILE)"
    fi
  else
    log "updatedb not available; skipping locate DB refresh"
  fi
  # Reload systemd daemons if present (new units might appear after kernel ops)
  if command -v systemctl >/dev/null 2>&1; then
    if systemctl daemon-reload >>"$LOG_FILE" 2>&1; then
      log "systemd daemon-reload completed"
    else
      log "WARNING: systemd daemon-reload failed (see $LOG_FILE)"
    fi
  fi
  if [[ "${UPDATE_GRUB_ENABLED:-false}" == "true" ]]; then
    UPDATE_GRUB_RAN=true
    if command -v update-grub >/dev/null 2>&1; then
      if update-grub >>"$LOG_FILE" 2>&1; then
        log "update-grub completed (GRUB configuration refreshed)"
        UPDATE_GRUB_SUCCESS=true
      else
        log "WARNING: update-grub failed (see $LOG_FILE)"
        UPDATE_GRUB_SUCCESS=false
      fi
    else
      log "update-grub not found; skipping explicit grub configuration refresh"
      UPDATE_GRUB_SUCCESS=false
    fi
  fi
  log "=== Post-kernel finalization complete ==="
}

kernel_status() {
  log "=== Kernel status check ==="
  local curr
  curr=$(uname -r)
  log "Current kernel: $curr"

  # Check for upgradable kernel packages
  local upgradable
  upgradable=$(apt list --upgradable 2>/dev/null || true)
  if [[ -z "$upgradable" ]]; then
    log "No upgradable packages reported by 'apt list --upgradable' or the command is unavailable."
  else
    # Filter for common kernel package names
    # Use a subshell with command substitution for POSIX-ish compatibility instead of process substitution
    KERNEL_UPGRADE_LIST=()
    # Avoid process substitution in environments where it's restricted by using a temp file
    _sm_tmp_kern="$LOG_DIR/kern_up_${RUN_ID}.txt"
    printf '%s\n' "$upgradable" | grep -E 'linux-(image|headers)|linux-image|linux-headers' >"$_sm_tmp_kern" 2>/dev/null || true
    while IFS= read -r _line; do
      [[ -n "$_line" ]] && KERNEL_UPGRADE_LIST+=("$_line")
    done <"$_sm_tmp_kern" || true
    rm -f "$_sm_tmp_kern" 2>/dev/null || true
    if ((${#KERNEL_UPGRADE_LIST[@]})); then
      log "Kernel packages available for upgrade:"
      for l in "${KERNEL_UPGRADE_LIST[@]}"; do
        log "+ $l"
      done
    else
      log "No kernel packages found among upgradable packages."
    fi
  fi

  if [[ -f /var/run/reboot-required ]]; then
    log "Reboot required (file /var/run/reboot-required present)."
    SUMMARY_REBOOT_REQUIRED=true
  else
    log "No reboot required (no /var/run/reboot-required file)."
  fi
  log "=== Kernel status check complete ==="
}
