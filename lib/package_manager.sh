#!/usr/bin/env bash
# Package Manager Abstraction Layer for sysmaint
# sysmaint library
# Purpose: Unified interface for APT, DNF, Pacman, and Zypper package managers
#
# This abstraction layer provides distro-agnostic functions for package management
# operations, allowing sysmaint to run on multiple Linux distributions.

# Global variable to store detected package manager
PKG_MANAGER=""
PKG_MANAGER_TYPE=""  # apt, dnf, pacman, zypper

# Detect the package manager based on available commands
detect_package_manager() {
  if command -v dnf >/dev/null 2>&1; then
    PKG_MANAGER="dnf"
    PKG_MANAGER_TYPE="dnf"
  elif command -v yum >/dev/null 2>&1; then
    PKG_MANAGER="yum"
    PKG_MANAGER_TYPE="dnf"  # YUM uses same syntax as DNF
  elif command -v apt-get >/dev/null 2>&1; then
    PKG_MANAGER="apt-get"
    PKG_MANAGER_TYPE="apt"
  elif command -v pacman >/dev/null 2>&1; then
    PKG_MANAGER="pacman"
    PKG_MANAGER_TYPE="pacman"
  elif command -v zypper >/dev/null 2>&1; then
    PKG_MANAGER="zypper"
    PKG_MANAGER_TYPE="zypper"
  else
    echo "ERROR: No supported package manager found" >&2
    return 1
  fi
  
  log "Detected package manager: $PKG_MANAGER (type: $PKG_MANAGER_TYPE)"
  return 0
}

# ============================================================================
# CORE PACKAGE OPERATIONS
# ============================================================================

# Update package metadata/cache
pkg_update() {
  case "$PKG_MANAGER_TYPE" in
    apt)
      run apt-get update -o Acquire::Retries=3
      ;;
    dnf)
      run "$PKG_MANAGER" makecache
      ;;
    pacman)
      run pacman -Sy
      ;;
    zypper)
      run zypper refresh
      ;;
    *)
      log "ERROR: Unknown package manager type: $PKG_MANAGER_TYPE"
      return 1
      ;;
  esac
}

# Upgrade installed packages
pkg_upgrade() {
  _pkg_ensure_initialized || return 1
  case "$PKG_MANAGER_TYPE" in
    apt)
      run apt-get -y -o Dpkg::Options::="--force-confold" upgrade
      ;;
    dnf)
      run "$PKG_MANAGER" -y upgrade
      ;;
    pacman)
      run pacman -Su --noconfirm
      ;;
    zypper)
      run zypper -n update
      ;;
    *)
      log "ERROR: Unknown package manager type: $PKG_MANAGER_TYPE"
      return 1
      ;;
  esac
}

# Full system upgrade (dist-upgrade equivalent)
pkg_full_upgrade() {
  _pkg_ensure_initialized || return 1
  case "$PKG_MANAGER_TYPE" in
    apt)
      run apt-get -y -o Dpkg::Options::="--force-confold" full-upgrade
      ;;
    dnf)
      run "$PKG_MANAGER" -y distro-sync
      ;;
    pacman)
      run pacman -Syu --noconfirm
      ;;
    zypper)
      run zypper -n dist-upgrade
      ;;
    *)
      log "ERROR: Unknown package manager type: $PKG_MANAGER_TYPE"
      return 1
      ;;
  esac
}

# Fix broken packages
pkg_fix_broken() {
  _pkg_ensure_initialized || return 1
  case "$PKG_MANAGER_TYPE" in
    apt)
      run dpkg --configure -a || true
      run apt-get -y -f install || true
      ;;
    dnf)
      # DNF doesn't have the same broken package concept as APT
      # This is mainly to ensure transaction is complete
      run "$PKG_MANAGER" -y distro-sync || true
      ;;
    pacman)
      # Pacman rarely has broken packages, but we can try to fix keyring issues
      run pacman-key --populate archlinux || true
      ;;
    zypper)
      run zypper -n verify || true
      ;;
    *)
      log "ERROR: Unknown package manager type: $PKG_MANAGER_TYPE"
      return 1
      ;;
  esac
}

# Remove unused dependencies
pkg_autoremove() {
  _pkg_ensure_initialized || return 1
  case "$PKG_MANAGER_TYPE" in
    apt)
      run apt-get -y autoremove --purge
      ;;
    dnf)
      run "$PKG_MANAGER" -y autoremove
      ;;
    pacman)
      # Pacman doesn't have direct autoremove, use -Qdtq to find orphans
      # WARNING: This can remove packages that were intentionally installed!
      # Always review orphan list before running without --dry-run
      local orphans
      orphans=$(pacman -Qdtq 2>/dev/null || true)
      if [[ -n "$orphans" ]]; then
        if [[ "${DRY_RUN:-false}" == "true" ]]; then
          log "DRY_RUN: would remove orphan packages:"
          echo "$orphans" | while read -r pkg; do log "  - $pkg"; done
        else
          log "Removing orphan packages: $(echo "$orphans" | tr '\n' ' ')"
          echo "$orphans" | xargs -r pacman -Rns --noconfirm
        fi
      else
        log "No orphan packages found"
      fi
      ;;

    zypper)
      # Get list of unneeded packages first, then remove with DRY_RUN check
      local unneeded
      unneeded=$(zypper -n packages --unneeded 2>/dev/null | tail -n +5 | awk '{print $5}' | grep -v '^$' || true)
      if [[ -n "$unneeded" ]]; then
        if [[ "${DRY_RUN:-false}" == "true" ]]; then
          log "DRY_RUN: would remove unneeded packages:"
          echo "$unneeded" | while read -r pkg; do log "  - $pkg"; done
        else
          log "Removing unneeded packages: $(echo "$unneeded" | tr '\n' ' ')"
          echo "$unneeded" | xargs -r zypper -n remove
        fi
      else
        log "No unneeded packages found"
      fi
      ;;

    *)
      log "ERROR: Unknown package manager type: $PKG_MANAGER_TYPE"
      return 1
      ;;
  esac
}

# Clean package cache
pkg_autoclean() {
  _pkg_ensure_initialized || return 1
  case "$PKG_MANAGER_TYPE" in
    apt)
      run apt-get -y autoclean
      ;;
    dnf)
      run "$PKG_MANAGER" clean packages
      ;;
    pacman)
      run pacman -Sc --noconfirm
      ;;
    zypper)
      run zypper clean
      ;;
    *)
      log "ERROR: Unknown package manager type: $PKG_MANAGER_TYPE"
      return 1
      ;;
  esac
}

# Remove a package
pkg_remove() {
  _pkg_ensure_initialized || return 1
  local pkg="$1"
  case "$PKG_MANAGER_TYPE" in
    apt)
      run apt-get -y purge "$pkg"
      ;;
    dnf)
      run "$PKG_MANAGER" -y remove "$pkg"
      ;;
    pacman)
      run pacman -Rns --noconfirm "$pkg"
      ;;
    zypper)
      run zypper -n remove "$pkg"
      ;;
    *)
      log "ERROR: Unknown package manager type: $PKG_MANAGER_TYPE"
      return 1
      ;;
  esac
}

# ============================================================================
# PACKAGE QUERY OPERATIONS
# ============================================================================

# List all installed packages
pkg_list_installed() {
  _pkg_ensure_initialized || return 1
  case "$PKG_MANAGER_TYPE" in
    apt)
      dpkg -l 2>/dev/null | awk '/^ii/ {print $2}'
      ;;
    dnf)
      rpm -qa --queryformat '%{NAME}\n'
      ;;
    pacman)
      pacman -Q | awk '{print $1}'
      ;;
    zypper)
      zypper -n packages --installed-only | tail -n +5 | awk '{print $3}'
      ;;
    *)
      log "ERROR: Unknown package manager type: $PKG_MANAGER_TYPE"
      return 1
      ;;
  esac
}

# List upgradable packages
pkg_list_upgradable() {
  _pkg_ensure_initialized || return 1
  case "$PKG_MANAGER_TYPE" in
    apt)
      apt list --upgradable 2>/dev/null
      ;;
    dnf)
      "$PKG_MANAGER" list --upgrades 2>/dev/null
      ;;
    pacman)
      pacman -Qu 2>/dev/null || true
      ;;
    zypper)
      zypper -n list-updates 2>/dev/null
      ;;
    *)
      log "ERROR: Unknown package manager type: $PKG_MANAGER_TYPE"
      return 1
      ;;
  esac
}

# Query package size (installed size in KB)
pkg_query_size() {
  _pkg_ensure_initialized || return 1
  local pkg="$1"
  case "$PKG_MANAGER_TYPE" in
    apt)
      dpkg-query -W -f='${Installed-Size}' "$pkg" 2>/dev/null || echo "0"
      ;;
    dnf)
      rpm -q --queryformat '%{SIZE}' "$pkg" 2>/dev/null | awk '{print int($1/1024)}' || echo "0"
      ;;
    pacman)
      pacman -Qi "$pkg" 2>/dev/null | awk '/^Installed Size/ {print int($4)}' || echo "0"
      ;;
    zypper)
      zypper -n info "$pkg" 2>/dev/null | awk '/^Installed Size/ {print int($4)}' || echo "0"
      ;;
    *)
      log "ERROR: Unknown package manager type: $PKG_MANAGER_TYPE"
      echo "0"
      return 1
      ;;
  esac
}

# Check if package is installed
pkg_is_installed() {
  _pkg_ensure_initialized || return 1
  local pkg="$1"
  case "$PKG_MANAGER_TYPE" in
    apt)
      dpkg -l "$pkg" 2>/dev/null | awk '/^ii/ {exit 0} END{exit 1}'
      ;;
    dnf)
      rpm -q "$pkg" >/dev/null 2>&1
      ;;
    pacman)
      pacman -Q "$pkg" >/dev/null 2>&1
      ;;
    zypper)
      zypper -n search -i "$pkg" | grep -q "^i "
      ;;
    *)
      log "ERROR: Unknown package manager type: $PKG_MANAGER_TYPE"
      return 1
      ;;
  esac
}

# Compare two version strings
# Returns 0 if version1 > version2, 1 if version1 < version2, 2 if equal
pkg_compare_versions() {
  _pkg_ensure_initialized || return 1
  local ver1="$1"
  local ver2="$2"
  
  case "$PKG_MANAGER_TYPE" in
    apt)
      dpkg --compare-versions "$ver1" gt "$ver2" && return 0
      dpkg --compare-versions "$ver1" lt "$ver2" && return 1
      return 2
      ;;
    dnf)
      # Use rpm's version comparison
      rpmdev-vercmp "$ver1" "$ver2" 2>/dev/null || {
        # Fallback to string comparison if rpmdev-vercmp not available
        [[ "$ver1" > "$ver2" ]] && return 0
        [[ "$ver1" < "$ver2" ]] && return 1
        return 2
      }
      ;;
    pacman)
      vercmp "$ver1" "$ver2"
      local result=$?
      [[ $result -eq 1 ]] && return 0  # greater
      [[ $result -eq -1 ]] && return 1 # less
      return 2  # equal
      ;;
    zypper)
      # Zypper doesn't have built-in version compare, use sort
      [[ "$ver1" == "$ver2" ]] && return 2
      [[ "$(printf '%s\n' "$ver1" "$ver2" | sort -V | head -1)" == "$ver2" ]] && return 0
      return 1
      ;;
    *)
      log "ERROR: Unknown package manager type: $PKG_MANAGER_TYPE"
      return 1
      ;;
  esac
}

# Find orphaned packages (no longer needed)
pkg_find_orphans() {
  _pkg_ensure_initialized || return 1
  case "$PKG_MANAGER_TYPE" in
    apt)
      # Use deborphan if available, otherwise apt-mark
      if command -v deborphan >/dev/null 2>&1; then
        deborphan
      else
        apt-mark showauto | while read -r pkg; do
          if ! apt-cache rdepends "$pkg" 2>/dev/null | grep -q "^ "; then
            echo "$pkg"
          fi
        done
      fi
      ;;
    dnf)
      "$PKG_MANAGER" leaves 2>/dev/null || package-cleanup --leaves 2>/dev/null || true
      ;;
    pacman)
      pacman -Qdtq 2>/dev/null || true
      ;;
    zypper)
      zypper -n packages --unneeded 2>/dev/null | tail -n +5 | awk '{print $5}' || true
      ;;
    *)
      log "ERROR: Unknown package manager type: $PKG_MANAGER_TYPE"
      return 1
      ;;
  esac
}

# ============================================================================
# LOCK FILE MANAGEMENT
# ============================================================================

# Get lock file paths for the current package manager
pkg_get_lock_files() {
  _pkg_ensure_initialized || return 1
  case "$PKG_MANAGER_TYPE" in
    apt)
      echo "/var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock"
      ;;
    dnf)
      echo "/var/cache/dnf/*.lock /var/lib/dnf/rpmdb_indexes.lock /var/lib/rpm/.rpm.lock"
      ;;
    pacman)
      echo "/var/lib/pacman/db.lck"
      ;;
    zypper)
      echo "/var/run/zypp.pid"
      ;;
    *)
      log "ERROR: Unknown package manager type: $PKG_MANAGER_TYPE"
      return 1
      ;;
  esac
}

# Get process names that might hold locks
pkg_get_lock_processes() {
  _pkg_ensure_initialized || return 1
  case "$PKG_MANAGER_TYPE" in
    apt)
      echo "apt apt-get dpkg unattended-upgrade"
      ;;
    dnf)
      echo "dnf yum packagekitd"
      ;;
    pacman)
      echo "pacman"
      ;;
    zypper)
      echo "zypper"
      ;;
    *)
      log "ERROR: Unknown package manager type: $PKG_MANAGER_TYPE"
      return 1
      ;;
  esac
}

# ============================================================================
# INITIALIZATION
# ============================================================================

# Lazy initialization: detect package manager when first pkg_* function is called
# This avoids calling log() before LOG_FILE is initialized in the main script
_pkg_ensure_initialized() {
  if [[ -z "$PKG_MANAGER" ]]; then
    detect_package_manager || {
      log "WARNING: Package manager auto-detection failed"
      return 1
    }
    log "Package manager abstraction layer loaded (manager: $PKG_MANAGER, type: $PKG_MANAGER_TYPE)"
  fi
}
