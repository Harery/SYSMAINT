#!/usr/bin/env bash
# lib/os_families/arch_family.sh - Arch Linux family-specific operations
# This file contains functions specific to Arch-based distributions
# Loaded for: Arch Linux, Manjaro, EndeavourOS (CI-tested)
# Compatible with: Any Arch-based distribution using pacman

# ============================================================================
# ARCH FAMILY SPECIFIC FUNCTIONS
# ============================================================================

# Arch-specific repository validation
arch_validate_repos() {
  log "Arch family repository validation"
  
  # Check pacman.conf exists and is readable
  if [[ ! -r /etc/pacman.conf ]]; then
    log "ERROR: /etc/pacman.conf not found or not readable"
    return 1
  fi
  
  # Check for enabled repositories
  local enabled_repos
  enabled_repos=$(grep -E '^\[.*\]' /etc/pacman.conf | grep -v '\[options\]' | wc -l)
  log "Active repositories in pacman.conf: $enabled_repos"
  
  # Check mirrorlist
  if [[ -r /etc/pacman.d/mirrorlist ]]; then
    local active_mirrors
    active_mirrors=$(grep -E '^Server\s*=' /etc/pacman.d/mirrorlist | wc -l)
    log "Active mirrors in mirrorlist: $active_mirrors"
    
    if (( active_mirrors == 0 )); then
      log "WARNING: No active mirrors found in /etc/pacman.d/mirrorlist"
    fi
  else
    log "WARNING: /etc/pacman.d/mirrorlist not found"
  fi
  
  # Check for .pacnew files (unmerged config updates)
  local pacnew_count
  pacnew_count=$(find /etc -name '*.pacnew' 2>/dev/null | wc -l)
  if (( pacnew_count > 0 )); then
    log "WARNING: Found $pacnew_count unmerged .pacnew configuration files"
  fi
}

# Arch kernel pattern (linux instead of kernel-)
arch_kernel_pattern() {
  echo "linux"
}

# Arch kernel purge (keep last 2 kernels)
arch_purge_old_kernels() {
  log "=== Arch kernel purge phase ==="
  
  if [[ "${PURGE_OLD_KERNELS:-false}" != "true" ]]; then
    log "Kernel purge disabled (enable with --purge-kernels or PURGE_OLD_KERNELS=true)"
    return 0
  fi
  
  # Get currently running kernel
  local running_kernel
  running_kernel=$(uname -r)
  log "Current running kernel: $running_kernel"
  
  # List installed kernels (linux, linux-lts, linux-zen, etc.)
  local all_kernels
  all_kernels=$(pacman -Qq | grep -E '^linux(-lts|-zen|-hardened)?$' | sort -V)
  
  # Count kernels
  local kernel_count
  kernel_count=$(echo "$all_kernels" | grep -c '^')
  
  if (( kernel_count <= 2 )); then
    log "Only $kernel_count kernel(s) installed, no purge needed (keeping minimum 2)"
    return 0
  fi
  
  log "Found $kernel_count kernels installed"
  
  # Determine which kernel is running
  local running_pkg=""
  if echo "$running_kernel" | grep -q 'lts'; then
    running_pkg="linux-lts"
  elif echo "$running_kernel" | grep -q 'zen'; then
    running_pkg="linux-zen"
  elif echo "$running_kernel" | grep -q 'hardened'; then
    running_pkg="linux-hardened"
  else
    running_pkg="linux"
  fi
  
  log "Running kernel package: $running_pkg"
  
  # Remove old kernels (keeping running + latest)
  for kernel_pkg in $all_kernels; do
    # Don't remove running kernel or latest linux package
    if [[ "$kernel_pkg" == "$running_pkg" ]] || [[ "$kernel_pkg" == "linux" ]]; then
      log "Keeping kernel: $kernel_pkg"
      continue
    fi
    
    log "Removing old kernel: $kernel_pkg"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
      log "DRY_RUN: would remove $kernel_pkg"
    else
      pacman -Rns --noconfirm "$kernel_pkg" >>"$LOG_FILE" 2>&1 || log "WARNING: Failed to remove $kernel_pkg"
    fi
  done
  
  log "Kernel purge complete"
}

# Detect desktop environment
arch_detect_desktop() {
  local desktop=""
  
  # Check for common desktop environments
  if pacman -Qq | grep -q '^gnome-shell$'; then
    desktop="GNOME"
  elif pacman -Qq | grep -q '^plasma-desktop$'; then
    desktop="KDE Plasma"
  elif pacman -Qq | grep -q '^xfce4-session$'; then
    desktop="Xfce"
  elif pacman -Qq | grep -q '^cinnamon$'; then
    desktop="Cinnamon"
  elif pacman -Qq | grep -q '^mate-session-manager$'; then
    desktop="MATE"
  elif pacman -Qq | grep -q '^lxde-common$'; then
    desktop="LXDE"
  elif pacman -Qq | grep -q '^lxqt-session$'; then
    desktop="LXQt"
  elif pacman -Qq | grep -q '^i3-wm$'; then
    desktop="i3"
  elif pacman -Qq | grep -q '^awesome$'; then
    desktop="Awesome"
  else
    desktop="Unknown/None"
  fi
  
  echo "$desktop"
}

# Find orphaned packages (no longer needed)
arch_find_orphans() {
  log "=== Finding orphaned packages ==="
  
  local orphans
  orphans=$(pacman -Qtdq 2>/dev/null)
  
  if [[ -z "$orphans" ]]; then
    log "No orphaned packages found"
    return 0
  fi
  
  local orphan_count
  orphan_count=$(echo "$orphans" | wc -l)
  log "Found $orphan_count orphaned package(s)"
  
  if [[ "${REMOVE_ORPHANS:-false}" == "true" ]]; then
    log "Removing orphaned packages..."
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
      log "DRY_RUN: would remove orphans: $(echo $orphans | tr '\n' ' ')"
    else
      echo "$orphans" | pacman -Rns --noconfirm - >>"$LOG_FILE" 2>&1 || log "WARNING: Failed to remove some orphans"
    fi
  else
    log "To remove orphans, run with --remove-orphans or REMOVE_ORPHANS=true"
  fi
  
  return 0
}

# Clean pacman cache
arch_cleanup_cache() {
  log "=== Cleaning pacman cache ==="
  
  # Check cache size before cleaning
  local cache_size_before=0
  if [[ -d /var/cache/pacman/pkg ]]; then
    cache_size_before=$(du -sm /var/cache/pacman/pkg 2>/dev/null | awk '{print $1}')
    log "Cache size before: ${cache_size_before}MB"
  fi
  
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "DRY_RUN: would clean pacman cache"
    # Show what would be cleaned
    local old_packages
    old_packages=$(paccache -d 2>/dev/null | wc -l)
    log "DRY_RUN: would remove $old_packages old package(s)"
  else
    # Keep last 2 versions of installed packages, remove uninstalled packages
    if command -v paccache >/dev/null 2>&1; then
      log "Using paccache to clean cache (keeping 2 versions)"
      paccache -r -k 2 >>"$LOG_FILE" 2>&1 || log "WARNING: paccache failed"
      paccache -ruk0 >>"$LOG_FILE" 2>&1 || log "WARNING: paccache uninstalled cleanup failed"
    else
      log "paccache not found, using pacman -Sc"
      yes | pacman -Sc >>"$LOG_FILE" 2>&1 || log "WARNING: pacman -Sc failed"
    fi
    
    # Check cache size after cleaning
    local cache_size_after=0
    if [[ -d /var/cache/pacman/pkg ]]; then
      cache_size_after=$(du -sm /var/cache/pacman/pkg 2>/dev/null | awk '{print $1}')
      local freed=$((cache_size_before - cache_size_after))
      log "Cache size after: ${cache_size_after}MB (freed ${freed}MB)"
    fi
  fi
  
  log "Cache cleanup complete"
}

# Detect AUR helper
arch_aur_helper_detect() {
  local aur_helper=""
  
  if command -v yay >/dev/null 2>&1; then
    aur_helper="yay"
  elif command -v paru >/dev/null 2>&1; then
    aur_helper="paru"
  elif command -v pikaur >/dev/null 2>&1; then
    aur_helper="pikaur"
  elif command -v trizen >/dev/null 2>&1; then
    aur_helper="trizen"
  elif command -v aurman >/dev/null 2>&1; then
    aur_helper="aurman"
  fi
  
  echo "$aur_helper"
}

# System upgrade finalization
arch_upgrade_finalize() {
  log "=== Arch system upgrade finalization ==="
  
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "DRY_RUN: would run pacman -Syu --noconfirm"
    return 0
  fi
  
  log "Running full system upgrade (pacman -Syu)..."
  if pacman -Syu --noconfirm >>"$LOG_FILE" 2>&1; then
    log "System upgrade completed successfully"
  else
    log "WARNING: System upgrade had errors (check log)"
  fi
  
  # Check if reboot is needed (kernel update)
  local running_kernel
  running_kernel=$(uname -r)
  local installed_kernel
  installed_kernel=$(pacman -Q linux 2>/dev/null | awk '{print $2}' | sed 's/-.*//') || installed_kernel=""
  
  if [[ -n "$installed_kernel" ]] && ! echo "$running_kernel" | grep -q "$installed_kernel"; then
    log "WARNING: Kernel was updated, reboot recommended"
    echo "reboot_recommended" >> "${STATE_FILE:-/tmp/sysmaint_state}"
  fi
}

# Check for failed systemd services
arch_check_failed_services() {
  log "=== Checking for failed systemd services ==="
  
  local failed_services
  failed_services=$(systemctl --failed --no-pager --no-legend | awk '{print $1}')
  
  if [[ -z "$failed_services" ]]; then
    log "No failed services found"
    return 0
  fi
  
  local failed_count
  failed_count=$(echo "$failed_services" | wc -l)
  log "WARNING: Found $failed_count failed service(s):"
  
  while IFS= read -r service; do
    log "  - $service"
  done <<< "$failed_services"
  
  return 0
}

# Update mirrorlist (with reflector if available)
arch_update_mirrorlist() {
  log "=== Updating mirrorlist ==="
  
  if ! command -v reflector >/dev/null 2>&1; then
    log "reflector not installed, skipping mirrorlist update"
    return 0
  fi
  
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "DRY_RUN: would update mirrorlist with reflector"
    return 0
  fi
  
  # Backup current mirrorlist
  if [[ -f /etc/pacman.d/mirrorlist ]]; then
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
    log "Backed up current mirrorlist"
  fi
  
  log "Running reflector to update mirrorlist..."
  if reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist >>"$LOG_FILE" 2>&1; then
    log "Mirrorlist updated successfully"
  else
    log "WARNING: reflector failed, restoring backup"
    if [[ -f /etc/pacman.d/mirrorlist.backup ]]; then
      mv /etc/pacman.d/mirrorlist.backup /etc/pacman.d/mirrorlist
    fi
  fi
}

# Sync package databases
arch_sync_databases() {
  log "=== Syncing package databases ==="
  
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "DRY_RUN: would sync databases (pacman -Sy)"
    return 0
  fi
  
  if pacman -Sy >>"$LOG_FILE" 2>&1; then
    log "Databases synced successfully"
  else
    log "WARNING: Database sync had errors"
    return 1
  fi
}

# Check for .pacsave files
arch_check_pacsave() {
  log "=== Checking for .pacsave files ==="
  
  local pacsave_files
  pacsave_files=$(find /etc -name '*.pacsave' 2>/dev/null)
  
  if [[ -z "$pacsave_files" ]]; then
    log "No .pacsave files found"
    return 0
  fi
  
  local pacsave_count
  pacsave_count=$(echo "$pacsave_files" | wc -l)
  log "Found $pacsave_count .pacsave file(s) (old configurations):"
  
  while IFS= read -r file; do
    log "  - $file"
  done <<< "$pacsave_files"
  
  return 0
}

# Initialize Arch family environment
arch_family_init() {
  log "=== Initializing Arch family environment ==="
  
  # Verify pacman is available
  if ! command -v pacman >/dev/null 2>&1; then
    log "ERROR: pacman not found, not an Arch-based system"
    return 1
  fi
  
  # Detect distribution variant
  local distro_variant="Arch Linux"
  if [[ -f /etc/os-release ]]; then
    distro_variant=$(grep '^NAME=' /etc/os-release | cut -d'"' -f2)
  fi
  log "Detected: $distro_variant"
  
  # Detect desktop environment
  local desktop
  desktop=$(arch_detect_desktop)
  log "Desktop environment: $desktop"
  
  # Detect AUR helper
  local aur_helper
  aur_helper=$(arch_aur_helper_detect)
  if [[ -n "$aur_helper" ]]; then
    log "AUR helper detected: $aur_helper"
  else
    log "No AUR helper detected"
  fi
  
  # Validate repositories
  arch_validate_repos
  
  log "Arch family initialization complete"
  return 0
}
