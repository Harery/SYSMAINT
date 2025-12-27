#!/usr/bin/env bash
# lib/redhat_family.sh - Red Hat/Fedora/CentOS family-specific operations
# This file contains functions specific to Red Hat-based distributions
# Loaded for: RHEL, Fedora, CentOS Stream (CI-tested)
# Also compatible with: Rocky Linux, AlmaLinux (untested but should work)

# ============================================================================
# RED HAT FAMILY SPECIFIC FUNCTIONS
# ============================================================================

# Red Hat-specific repository validation
redhat_validate_repos() {
  log "Red Hat family repository validation"
  
  # Check for enabled repositories
  if command -v dnf >/dev/null 2>&1; then
    local enabled_repos
    enabled_repos=$(dnf repolist enabled 2>/dev/null | grep -c '^[^!]' || echo 0)
    log "Active repositories: $enabled_repos"
  elif command -v yum >/dev/null 2>&1; then
    local enabled_repos
    enabled_repos=$(yum repolist enabled 2>/dev/null | grep -c '^[^!]' || echo 0)
    log "Active repositories: $enabled_repos"
  fi
  
  # Check for repo file issues
  if [[ -d /etc/yum.repos.d ]]; then
    local malformed
    malformed=$(find /etc/yum.repos.d -name '*.repo' -exec grep -L '\[' {} \; | wc -l)
    if (( malformed > 0 )); then
      log "WARNING: Found $malformed potentially malformed repo files"
    fi
  fi
}

# Red Hat kernel pattern (kernel-* instead of linux-image-*)
redhat_kernel_pattern() {
  echo "kernel-"
}

# Red Hat kernel purge (keep last 2 kernels)
redhat_purge_old_kernels() {
  log "=== Red Hat kernel purge phase ==="
  
  if [[ "${PURGE_OLD_KERNELS:-false}" != "true" ]]; then
    log "Kernel purge disabled (enable with --purge-kernels or PURGE_OLD_KERNELS=true)"
    return 0
  fi
  
  # Get currently running kernel
  local running_kernel
  running_kernel=$(uname -r)
  log "Current running kernel: $running_kernel"
  
  # List installed kernels
  local all_kernels
  if command -v dnf >/dev/null 2>&1; then
    all_kernels=$(dnf list installed 'kernel-*' 2>/dev/null | awk '/^kernel-[0-9]/ {print $1}' | sort -V)
  elif command -v rpm >/dev/null 2>&1; then
    all_kernels=$(rpm -qa 'kernel-*' | sort -V)
  else
    log "No package manager found for kernel purge"
    return 1
  fi
  
  # Keep running kernel + latest 2
  local kernel_count
  kernel_count=$(echo "$all_kernels" | wc -l)
  
  if (( kernel_count <= 3 )); then
    log "Only $kernel_count kernels installed, no purge needed (keeping minimum 3)"
    return 0
  fi
  
  # Remove old kernels (keeping last 3)
  local kernels_to_remove
  kernels_to_remove=$(echo "$all_kernels" | head -n -3)
  
  for kernel_pkg in $kernels_to_remove; do
    # Don't remove running kernel
    if echo "$kernel_pkg" | grep -q "$running_kernel"; then
      log "Skipping running kernel: $kernel_pkg"
      continue
    fi
    
    log "Removing old kernel: $kernel_pkg"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
      log "DRY_RUN: would remove $kernel_pkg"
    else
      if command -v dnf >/dev/null 2>&1; then
        dnf -y remove "$kernel_pkg" >>"$LOG_FILE" 2>&1 || log "WARNING: Failed to remove $kernel_pkg"
      elif command -v yum >/dev/null 2>&1; then
        yum -y remove "$kernel_pkg" >>"$LOG_FILE" 2>&1 || log "WARNING: Failed to remove $kernel_pkg"
      fi
    fi
  done
  
  log "Kernel purge complete"
}

# Detect Red Hat desktop vs server
redhat_detect_desktop() {
  if rpm -q gnome-shell >/dev/null 2>&1; then
    echo "desktop"
  elif rpm -q kde-plasma-desktop >/dev/null 2>&1; then
    echo "desktop"
  elif rpm -q xfce4-session >/dev/null 2>&1; then
    echo "desktop"
  else
    echo "server"
  fi
}

# Red Hat-specific upgrade finalize
redhat_upgrade_finalize() {
  log "=== Final upgrade pass (Red Hat family) ==="
  
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "DRY_RUN: would run distro-sync or upgrade"
    return 0
  fi
  
  local up_out up_rc
  set +e
  
  if command -v dnf >/dev/null 2>&1; then
    up_out=$(dnf -y distro-sync 2>&1)
    up_rc=$?
  elif command -v yum >/dev/null 2>&1; then
    up_out=$(yum -y distro-sync 2>&1)
    up_rc=$?
  else
    log "No package manager found for upgrade"
    return 1
  fi
  
  set -e
  
  printf '%s\n' "$up_out" | tee -a "$LOG_FILE" || true
  
  if (( up_rc == 0 )); then
    log "Final upgrade pass completed successfully"
  else
    log "WARNING: Final upgrade pass returned exit code $up_rc"
  fi
  
  return $up_rc
}

# Red Hat package group information
redhat_package_groups() {
  if command -v dnf >/dev/null 2>&1; then
    local groups_installed
    groups_installed=$(dnf group list --installed 2>/dev/null | grep -c 'Installed Groups' || echo 0)
    log "Package groups installed: $groups_installed"
  fi
}

# Check for Red Hat subscription status (RHEL only)
redhat_check_subscription() {
  if command -v subscription-manager >/dev/null 2>&1; then
    local status
    status=$(subscription-manager status 2>/dev/null | grep -i 'overall status' || echo "Unknown")
    log "RHEL Subscription: $status"
    
    if echo "$status" | grep -qi "unknown\|invalid\|expired"; then
      log "WARNING: RHEL subscription may need attention"
    fi
  fi
}

# Red Hat-specific orphan detection
redhat_find_orphans() {
  if command -v dnf >/dev/null 2>&1; then
    # DNF leaf packages (no dependents)
    dnf repoquery --installed --qf '%{name}' --leaves 2>/dev/null || true
  elif command -v package-cleanup >/dev/null 2>&1; then
    # Older systems with yum-utils
    package-cleanup --leaves --quiet 2>/dev/null || true
  fi
}

# Check for pending Red Hat updates that require reboot
redhat_check_reboot_required() {
  # Check needs-restarting (from yum-utils or dnf-utils)
  if command -v needs-restarting >/dev/null 2>&1; then
    if needs-restarting -r >/dev/null 2>&1; then
      return 1  # No reboot needed
    else
      log "System reboot required (needs-restarting indicates yes)"
      return 0  # Reboot needed
    fi
  fi
  
  # Fallback: check for kernel updates
  local installed_kernel running_kernel
  if command -v rpm >/dev/null 2>&1; then
    installed_kernel=$(rpm -q --last kernel | head -1 | awk '{print $1}')
    running_kernel="kernel-$(uname -r)"
    
    if [[ "$installed_kernel" != "$running_kernel" ]]; then
      log "Kernel update detected: $installed_kernel vs $running_kernel"
      return 0  # Reboot needed
    fi
  fi
  
  return 1  # No reboot needed
}

# Red Hat DNF/YUM cache statistics
redhat_cache_stats() {
  local cache_dir
  
  if command -v dnf >/dev/null 2>&1; then
    cache_dir="/var/cache/dnf"
  else
    cache_dir="/var/cache/yum"
  fi
  
  if [[ -d "$cache_dir" ]]; then
    local cache_size
    cache_size=$(du -sh "$cache_dir" 2>/dev/null | awk '{print $1}')
    log "Package cache: $cache_size"
  fi
}

# Red Hat-specific cleanup recommendations
redhat_cleanup_recommendations() {
  local recommendations=()
  
  # Check for old kernels
  local kernel_count
  kernel_count=$(rpm -qa 'kernel-*' 2>/dev/null | wc -l || echo 0)
  if (( kernel_count > 3 )); then
    recommendations+=("Consider enabling kernel purge: $((kernel_count - 2)) old kernels found")
  fi
  
  # Check for orphaned packages
  local orphan_count
  if command -v dnf >/dev/null 2>&1; then
    orphan_count=$(dnf repoquery --installed --qf '%{name}' --leaves 2>/dev/null | wc -l || echo 0)
    if (( orphan_count > 10 )); then
      recommendations+=("$orphan_count leaf packages found (potential orphans)")
    fi
  fi
  
  # Check for duplicate packages
  if command -v dnf >/dev/null 2>&1; then
    local duplicates
    duplicates=$(dnf repoquery --duplicates 2>/dev/null | wc -l || echo 0)
    if (( duplicates > 0 )); then
      recommendations+=("$duplicates duplicate packages found (run: dnf remove --duplicates)")
    fi
  fi
  
  # Return recommendations
  for rec in "${recommendations[@]}"; do
    log "RECOMMENDATION: $rec"
  done
}

# Fedora-specific: Check for system upgrade available
redhat_check_system_upgrade() {
  if command -v dnf >/dev/null 2>&1 && [[ -f /etc/fedora-release ]]; then
    # Check if system upgrade plugin is available
    if dnf plugin list 2>/dev/null | grep -q 'system-upgrade'; then
      log "INFO: Fedora system upgrade plugin available (use 'dnf system-upgrade' for major version upgrades)"
    fi
  fi
}

# SELinux status check
redhat_selinux_status() {
  if command -v getenforce >/dev/null 2>&1; then
    local selinux_status
    selinux_status=$(getenforce 2>/dev/null || echo "Unknown")
    log "SELinux status: $selinux_status"
    
    # Check for SELinux denials
    if command -v ausearch >/dev/null 2>&1; then
      local denials
      denials=$(ausearch -m avc -ts recent 2>/dev/null | grep -c 'denied' || echo 0)
      if (( denials > 0 )); then
        log "WARNING: $denials recent SELinux denials found"
      fi
    fi
  fi
}

# Initialize Red Hat family-specific variables
redhat_family_init() {
  log "Red Hat family module loaded"
  
  # Set DNF to automatically handle obsoletes
  export DNF_SKIP_BROKEN=0
  
  # Check if this is RHEL
  if [[ -f /etc/redhat-release ]]; then
    if grep -qi 'red hat enterprise' /etc/redhat-release; then
      export IS_RHEL=true
      redhat_check_subscription
    fi
  fi
}
