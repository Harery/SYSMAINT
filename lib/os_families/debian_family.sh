#!/usr/bin/env bash
# lib/debian_family.sh - Debian/Ubuntu family-specific operations
# This file contains functions specific to Debian-based distributions
# Loaded only when running on Debian/Ubuntu/Mint/etc.

# ============================================================================
# DEBIAN/UBUNTU SPECIFIC FUNCTIONS
# ============================================================================

# Check APT signature verification status
debian_apt_signature_check() {
  local update_out="$1"
  if printf '%s\n' "$update_out" | grep -qiE '(NO_PUBKEY|signature.*invalid|signature.*error)'; then
    echo "warning"
  elif printf '%s\n' "$update_out" | grep -qiE 'signature.*valid'; then
    echo "valid"
  else
    echo "unknown"
  fi
}

# Debian-specific repository validation
debian_validate_repos() {
  log "Debian/Ubuntu repository validation"
  # Check sources.list format
  if [[ -f /etc/apt/sources.list ]]; then
    local malformed
    malformed=$(grep -vE '^(#|$|deb )' /etc/apt/sources.list | wc -l)
    if (( malformed > 0 )); then
      log "WARNING: Found $malformed malformed lines in /etc/apt/sources.list"
    fi
  fi
  
  # Check for duplicate sources
  if command -v apt-cache >/dev/null 2>&1; then
    local duplicates
    duplicates=$(apt-cache policy 2>/dev/null | grep -c "Duplicate sources.list" || true)
    if (( duplicates > 0 )); then
      log "WARNING: Found duplicate sources in APT configuration"
    fi
  fi
}

# Ubuntu-specific kernel handling
debian_kernel_pattern() {
  # Debian/Ubuntu uses linux-image-* pattern
  echo "linux-image-"
}

# Check if Ubuntu/Debian desktop environment is installed
debian_detect_desktop() {
  if dpkg -l ubuntu-desktop 2>/dev/null | awk '/^ii/ {exit 0} END{exit 1}'; then
    echo "desktop"
  elif dpkg -l gnome-shell 2>/dev/null | awk '/^ii/ {exit 0} END{exit 1}'; then
    echo "desktop"
  elif dpkg -l kde-plasma-desktop 2>/dev/null | awk '/^ii/ {exit 0} END{exit 1}'; then
    echo "desktop"
  else
    echo "server"
  fi
}

# Debian-specific upgrade finalize
debian_upgrade_finalize() {
  log "=== Final upgrade pass (Debian/Ubuntu) ==="
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "DRY_RUN: would run: apt-get -y -o Dpkg::Options::=--force-confold full-upgrade"
    return 0
  fi
  
  local up_out up_rc
  set +e
  up_out=$(apt-get -y -o Dpkg::Options::=--force-confold full-upgrade 2>&1)
  up_rc=$?
  set -e
  
  printf '%s\n' "$up_out" | tee -a "$LOG_FILE" || true
  
  if (( up_rc == 0 )); then
    log "Final upgrade pass completed successfully"
  else
    log "WARNING: Final upgrade pass returned exit code $up_rc"
  fi
  
  return $up_rc
}

# Debian/Ubuntu specific orphan detection
debian_find_orphans() {
  if command -v deborphan >/dev/null 2>&1; then
    deborphan
  else
    # Fallback: parse apt-get autoremove -s
    apt-get -s autoremove 2>&1 | awk '/^Remv/ {print $2}'
  fi
}

# Check for pending Debian configuration
debian_check_pending_config() {
  local pending
  pending=$(dpkg -l | awk '/^[^i]/ && !/^Des/ && !/^|/ {print $2}' | wc -l)
  if (( pending > 0 )); then
    log "WARNING: $pending packages in non-installed state"
    return 1
  fi
  return 0
}

# Debian-specific security updates check
debian_security_updates() {
  if command -v apt-get >/dev/null 2>&1; then
    local security_updates
    security_updates=$(apt-get -s upgrade 2>/dev/null | grep -i security | wc -l || echo 0)
    echo "$security_updates"
  else
    echo "0"
  fi
}

# Ubuntu-specific release upgrade check
debian_check_release_upgrade() {
  if command -v do-release-upgrade >/dev/null 2>&1; then
    if do-release-upgrade --check-dist-upgrade-only 2>&1 | grep -q "New release"; then
      log "INFO: New Ubuntu release available (run do-release-upgrade to upgrade)"
      return 0
    fi
  fi
  return 1
}

# Debian APT cache statistics
debian_apt_cache_stats() {
  if [[ -d /var/cache/apt/archives ]]; then
    local cache_size cache_count
    cache_size=$(du -sh /var/cache/apt/archives 2>/dev/null | awk '{print $1}')
    cache_count=$(find /var/cache/apt/archives -name '*.deb' 2>/dev/null | wc -l)
    log "APT cache: $cache_size ($cache_count .deb files)"
  fi
}

# Debian-specific cleanup recommendations
debian_cleanup_recommendations() {
  local recommendations=()
  
  # Check for old kernels
  local kernel_count
  kernel_count=$(dpkg -l 'linux-image-*' 2>/dev/null | grep -c '^ii' || echo 0)
  if (( kernel_count > 3 )); then
    recommendations+=("Consider enabling kernel purge: $((kernel_count - 2)) old kernels found")
  fi
  
  # Check for orphaned packages
  if command -v deborphan >/dev/null 2>&1; then
    local orphan_count
    orphan_count=$(deborphan 2>/dev/null | wc -l || echo 0)
    if (( orphan_count > 0 )); then
      recommendations+=("$orphan_count orphaned packages found (enable --orphan-purge)")
    fi
  fi
  
  # Check for old config files
  local old_configs
  old_configs=$(dpkg -l | grep '^rc' | wc -l || echo 0)
  if (( old_configs > 0 )); then
    recommendations+=("$old_configs removed packages with residual config files")
  fi
  
  # Return recommendations
  for rec in "${recommendations[@]}"; do
    log "RECOMMENDATION: $rec"
  done
}

# Initialize Debian family-specific variables
debian_family_init() {
  export DEBIAN_FRONTEND=noninteractive
  log "Debian/Ubuntu family module loaded"
}
