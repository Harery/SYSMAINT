#!/usr/bin/env bash
# lib/os_families/suse_family.sh - SUSE family-specific operations
# This file contains functions specific to SUSE-based distributions
# Loaded for: openSUSE Tumbleweed, openSUSE Leap, SLES (CI-tested)
# Compatible with: Any SUSE-based distribution using zypper

# ============================================================================
# SUSE FAMILY SPECIFIC FUNCTIONS
# ============================================================================

# SUSE-specific repository validation
suse_validate_repos() {
  log "SUSE family repository validation"
  
  # Check if zypper is available
  if ! command -v zypper >/dev/null 2>&1; then
    log "ERROR: zypper not found"
    return 1
  fi
  
  # List all repositories
  local repo_list
  repo_list=$(zypper lr --details 2>/dev/null)
  
  # Count enabled repositories
  local enabled_repos
  enabled_repos=$(zypper lr 2>/dev/null | grep -c '|.*| Yes')
  log "Active repositories: $enabled_repos"
  
  if (( enabled_repos == 0 )); then
    log "WARNING: No enabled repositories found"
  fi
  
  # Check for repository issues
  if zypper ref --check 2>&1 | grep -qi "error\|problem"; then
    log "WARNING: Repository validation found issues"
  fi
  
  # Check for duplicate repositories
  local repo_count
  repo_count=$(zypper lr 2>/dev/null | wc -l)
  if (( repo_count > 20 )); then
    log "WARNING: Large number of repositories ($repo_count), may cause conflicts"
  fi
}

# SUSE kernel pattern (kernel-default instead of linux)
suse_kernel_pattern() {
  echo "kernel-default"
}

# SUSE kernel purge (keep last 2 kernels)
suse_purge_old_kernels() {
  log "=== SUSE kernel purge phase ==="
  
  if [[ "${PURGE_OLD_KERNELS:-false}" != "true" ]]; then
    log "Kernel purge disabled (enable with --purge-kernels or PURGE_OLD_KERNELS=true)"
    return 0
  fi
  
  # Get currently running kernel
  local running_kernel
  running_kernel=$(uname -r)
  log "Current running kernel: $running_kernel"
  
  # List installed kernel packages
  local all_kernels
  all_kernels=$(rpm -qa | grep -E '^kernel-(default|desktop|pae)' | sort -V)
  
  # Count kernels
  local kernel_count
  kernel_count=$(echo "$all_kernels" | grep -c '^kernel-')
  
  if (( kernel_count <= 2 )); then
    log "Only $kernel_count kernel(s) installed, no purge needed (keeping minimum 2)"
    return 0
  fi
  
  log "Found $kernel_count kernels installed"
  
  # Extract running kernel package name
  local running_pkg=""
  running_pkg=$(echo "$all_kernels" | grep "$running_kernel" | head -1)
  log "Running kernel package: ${running_pkg:-unknown}"
  
  # Get sorted list (oldest first)
  local sorted_kernels
  sorted_kernels=$(echo "$all_kernels" | head -n -2)  # Keep last 2
  
  # Remove old kernels
  for kernel_pkg in $sorted_kernels; do
    # Don't remove running kernel
    if [[ "$kernel_pkg" == "$running_pkg" ]]; then
      log "Keeping running kernel: $kernel_pkg"
      continue
    fi
    
    log "Removing old kernel: $kernel_pkg"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
      log "DRY_RUN: would remove $kernel_pkg"
    else
      zypper remove -y "$kernel_pkg" >>"$LOG_FILE" 2>&1 || log "WARNING: Failed to remove $kernel_pkg"
    fi
  done
  
  log "Kernel purge complete"
}

# Detect desktop environment
suse_detect_desktop() {
  local desktop=""
  
  # Check for common desktop environments
  if rpm -qa | grep -q '^gnome-shell-'; then
    desktop="GNOME"
  elif rpm -qa | grep -q '^plasma5-desktop-'; then
    desktop="KDE Plasma"
  elif rpm -qa | grep -q '^xfce4-session-'; then
    desktop="Xfce"
  elif rpm -qa | grep -q '^cinnamon-'; then
    desktop="Cinnamon"
  elif rpm -qa | grep -q '^mate-session-manager-'; then
    desktop="MATE"
  elif rpm -qa | grep -q '^lxde-common-'; then
    desktop="LXDE"
  elif rpm -qa | grep -q '^lxqt-session-'; then
    desktop="LXQt"
  elif rpm -qa | grep -q '^i3-'; then
    desktop="i3"
  elif rpm -qa | grep -q '^enlightenment-'; then
    desktop="Enlightenment"
  else
    desktop="Unknown/None"
  fi
  
  echo "$desktop"
}

# Find orphaned packages (no longer needed)
suse_find_orphans() {
  log "=== Finding orphaned packages ==="
  
  # zypper packages --orphaned shows packages from removed repos
  local orphans
  orphans=$(zypper packages --orphaned 2>/dev/null | grep '^\s*i\s*|' | awk -F'|' '{print $3}' | tr -d ' ')
  
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
      echo "$orphans" | while read -r pkg; do
        zypper remove -y "$pkg" >>"$LOG_FILE" 2>&1 || log "WARNING: Failed to remove $pkg"
      done
    fi
  else
    log "To remove orphans, run with --remove-orphans or REMOVE_ORPHANS=true"
  fi
  
  return 0
}

# Clean zypper cache
suse_cleanup_cache() {
  log "=== Cleaning zypper cache ==="
  
  # Check cache size before cleaning
  local cache_size_before=0
  if [[ -d /var/cache/zypp ]]; then
    cache_size_before=$(du -sm /var/cache/zypp 2>/dev/null | awk '{print $1}')
    log "Cache size before: ${cache_size_before}MB"
  fi
  
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "DRY_RUN: would clean zypper cache"
  else
    # Clean metadata and packages
    log "Cleaning zypper metadata and package cache..."
    zypper clean --all >>"$LOG_FILE" 2>&1 || log "WARNING: zypper clean failed"
    
    # Check cache size after cleaning
    local cache_size_after=0
    if [[ -d /var/cache/zypp ]]; then
      cache_size_after=$(du -sm /var/cache/zypp 2>/dev/null | awk '{print $1}')
      local freed=$((cache_size_before - cache_size_after))
      log "Cache size after: ${cache_size_after}MB (freed ${freed}MB)"
    fi
  fi
  
  log "Cache cleanup complete"
}

# Check for distribution upgrade available
suse_check_system_upgrade() {
  log "=== Checking for distribution upgrade ==="
  
  # Check if this is Tumbleweed (rolling) or Leap (fixed release)
  local version_id=""
  if [[ -f /etc/os-release ]]; then
    version_id=$(grep '^VERSION_ID=' /etc/os-release | cut -d'"' -f2)
  fi
  
  if [[ "$version_id" == *"tumbleweed"* ]] || grep -qi tumbleweed /etc/os-release 2>/dev/null; then
    log "openSUSE Tumbleweed detected (rolling release, no dist-upgrade needed)"
    return 0
  fi
  
  # For Leap, check if newer version is available
  if [[ -n "$version_id" ]]; then
    log "Current version: $version_id"
    # Note: Actual upgrade check would require network access to repositories
    log "To upgrade openSUSE Leap, use: zypper dup --releasever=<new-version>"
  fi
  
  return 0
}

# System upgrade finalization
suse_upgrade_finalize() {
  log "=== SUSE system upgrade finalization ==="
  
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "DRY_RUN: would run zypper dup --no-confirm"
    return 0
  fi
  
  log "Running distribution upgrade (zypper dup)..."
  if zypper dup --no-confirm >>"$LOG_FILE" 2>&1; then
    log "System upgrade completed successfully"
  else
    log "WARNING: System upgrade had errors (check log)"
  fi
  
  # Check if reboot is needed
  if [[ -f /var/run/reboot-required ]] || zypper ps -s 2>/dev/null | grep -q "^kernel"; then
    log "WARNING: System reboot recommended"
    echo "reboot_recommended" >> "${STATE_FILE:-/tmp/sysmaint_state}"
  fi
}

# Check for failed systemd services
suse_check_failed_services() {
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

# Refresh repositories
suse_refresh_repos() {
  log "=== Refreshing repositories ==="
  
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "DRY_RUN: would refresh repositories (zypper ref)"
    return 0
  fi
  
  if zypper ref >>"$LOG_FILE" 2>&1; then
    log "Repositories refreshed successfully"
  else
    log "WARNING: Repository refresh had errors"
    return 1
  fi
}

# Check for .rpmsave/.rpmnew files
suse_check_rpmsave() {
  log "=== Checking for .rpmsave/.rpmnew files ==="
  
  local config_files
  config_files=$(find /etc -name '*.rpmsave' -o -name '*.rpmnew' 2>/dev/null)
  
  if [[ -z "$config_files" ]]; then
    log "No .rpmsave/.rpmnew files found"
    return 0
  fi
  
  local file_count
  file_count=$(echo "$config_files" | wc -l)
  log "Found $file_count configuration backup file(s):"
  
  while IFS= read -r file; do
    log "  - $file"
  done <<< "$config_files"
  
  return 0
}

# Initialize SUSE family environment
suse_family_init() {
  log "=== Initializing SUSE family environment ==="
  
  # Verify zypper is available
  if ! command -v zypper >/dev/null 2>&1; then
    log "ERROR: zypper not found, not a SUSE-based system"
    return 1
  fi
  
  # Detect distribution variant
  local distro_variant="SUSE Linux"
  if [[ -f /etc/os-release ]]; then
    distro_variant=$(grep '^NAME=' /etc/os-release | cut -d'"' -f2)
  fi
  log "Detected: $distro_variant"
  
  # Detect version
  local version_id=""
  if [[ -f /etc/os-release ]]; then
    version_id=$(grep '^VERSION_ID=' /etc/os-release | cut -d'"' -f2)
    log "Version: $version_id"
  fi
  
  # Detect desktop environment
  local desktop
  desktop=$(suse_detect_desktop)
  log "Desktop environment: $desktop"
  
  # Validate repositories
  suse_validate_repos
  
  log "SUSE family initialization complete"
  return 0
}
