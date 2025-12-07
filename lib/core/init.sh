#!/usr/bin/env bash
# lib/core/init.sh - System initialization and OS detection
# Part of sysmaint v2.2.0 modular architecture
# Copyright (c) 2025 Mohamed Elharery

# Functions:
#   check_os()                - Detect OS family and load family-specific libraries
#   is_effective_root()       - Check if running with root/sudo privileges
#   require_root()            - Enforce root requirement with helpful message
#   _init_state_dir()         - Initialize state directory for persistent data
#   _state_file()             - Get path to state file for a given key

# This module handles system initialization, OS detection, and privilege checking.
# It loads the appropriate OS family library (Debian, Red Hat, Arch, SUSE) based
# on the detected distribution.

check_os() {
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    
    # v2.2.0: Multi-distro support - detect distro family
    # Supported: Debian/Ubuntu, RHEL/Rocky/Alma/CentOS/Fedora, Arch/Manjaro, openSUSE
    local supported=false
    
    # Debian family
    if [[ "${ID:-}" == "ubuntu" || "${ID:-}" == "debian" || "${ID_LIKE:-}" == *debian* ]]; then
      supported=true
      log "Detected Debian/Ubuntu family: ${ID:-unknown}"
      # Load Debian family-specific library
      if [[ -f "$SCRIPT_DIR/lib/os_families/debian_family.sh" ]]; then
        source "$SCRIPT_DIR/lib/os_families/debian_family.sh"
        debian_family_init
      fi
    
    # Red Hat family
    elif [[ "${ID:-}" == "rhel" || "${ID:-}" == "centos" || "${ID:-}" == "fedora" || \
            "${ID:-}" == "rocky" || "${ID:-}" == "almalinux" || \
            "${ID_LIKE:-}" == *rhel* || "${ID_LIKE:-}" == *fedora* ]]; then
      supported=true
      log "Detected Red Hat family: ${ID:-unknown}"
      # Load Red Hat family-specific library
      if [[ -f "$SCRIPT_DIR/lib/os_families/redhat_family.sh" ]]; then
        source "$SCRIPT_DIR/lib/os_families/redhat_family.sh"
        redhat_family_init
      fi
    
    # Arch family
    elif [[ "${ID:-}" == "arch" || "${ID:-}" == "manjaro" || "${ID_LIKE:-}" == *arch* ]]; then
      supported=true
      log "Detected Arch family: ${ID:-unknown}"
      # TODO: Load Arch family-specific library when created
    
    # SUSE family
    elif [[ "${ID:-}" == "opensuse" || "${ID:-}" == "opensuse-leap" || "${ID:-}" == "opensuse-tumbleweed" || \
            "${ID_LIKE:-}" == *suse* ]]; then
      supported=true
      log "Detected SUSE family: ${ID:-unknown}"
      # TODO: Load SUSE family-specific library when created
    fi
    
    if [[ "$supported" == "false" ]]; then
      echo "ERROR: Unsupported distribution: ${ID:-unknown}" >&2
      echo "Supported: Ubuntu, Debian, RHEL, Rocky, Alma, CentOS, Fedora, Arch, Manjaro, openSUSE" >&2
      exit 1
    fi
  else
    echo "ERROR: Cannot read /etc/os-release" >&2
    exit 1
  fi
}

is_effective_root() {
  if [[ $EUID -eq 0 ]]; then
    return 0
  fi
  if [[ "$FAKE_ROOT_ACTIVE" == "true" ]]; then
    return 0
  fi
  return 1
}

require_root() {
  # Defensive: if --dry-run is present in args, set DRY_RUN early so we
  # never attempt elevation during preview runs (regardless of prior parsing).
  for _ra in "$@"; do
    if [[ "$_ra" == "--dry-run" ]]; then
      DRY_RUN=true
      break
    fi
  done

  # Dry-runs and sandboxed fake-root sessions may proceed without elevation.
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    return 0
  fi

  if is_effective_root; then
    if [[ "$FAKE_ROOT_ACTIVE" == "true" && "$FAKE_ROOT_NOTICE_SHOWN" != "true" ]]; then
      log "SYSMAINT_FAKE_ROOT=1 detected: bypassing sudo for sandbox validation. Do not enable this mode on production systems."
      FAKE_ROOT_NOTICE_SHOWN=true
    fi
    return 0
  fi

  # If not running as root and not in DRY_RUN, attempt to re-exec with sudo
  # so users can simply run the script without typing sudo themselves.
  if command -v sudo >/dev/null 2>&1; then
    log "Attempting non-interactive sudo elevation..."
    # Preserve a curated set of environment variables across sudo to avoid
    # losing flags like DRY_RUN, CLEAR_TMP, ASSUME_YES, etc. We will only
    # attempt non-interactive elevation; do NOT fall back to interactive
    # sudo because that prompts the user, which we avoid.
    preserve_env=(
      DRY_RUN CLEAR_TMP CLEAR_TMP_FORCE CLEAR_TMP_AGE_DAYS ASSUME_YES
      AUTO_REBOOT LOG_DIR LOCKFILE JSON_SUMMARY SIMULATE_UPGRADE FIX_MISSING_KEYS
      NO_SNAP PROGRESS_MODE PROGRESS_DURATION LOCK_WAIT_SECONDS
      WAIT_MAX_RETRIES WAIT_TIMEOUT_SECONDS STALE_LOCK_THRESHOLD ONLY_CHECK_LOCKS FORCE_STAT_LOCK_CHECK
    )

    env_prefix=(env)
    for v in "${preserve_env[@]}"; do
      if [[ -n "${!v:-}" ]]; then
        val="${!v//\"/\\\"}"
        env_prefix+=("$v=$val")
      fi
    done

    # Attempt non-interactive sudo. If it fails, exit with a clear message
    # rather than prompting for password to avoid interrupting the user.
    if sudo -n true >/dev/null 2>&1; then
      exec sudo -E "${env_prefix[@]}" bash "$0" "$@"
    else
      echo "ERROR: This script requires root privileges. Non-interactive sudo failed (password required)." >&2
      echo "Run with 'sudo' interactively, or configure passwordless sudo for this user if you want unattended runs." >&2
      exit 1
    fi
  else
    echo "ERROR: run as root (use sudo)." >&2
    exit 1
  fi
}

_is_root_user() {
  [[ $EUID -eq 0 ]]
}

_init_state_dir() {
  if [[ -n "$STATE_DIR" ]]; then
    :
  elif _is_root_user; then
    STATE_DIR="/var/lib/sysmaint"
  else
    STATE_DIR="$HOME/.local/state/sysmaint"
  fi
  mkdir -p "$STATE_DIR" 2>/dev/null || true
}

_state_file() {
  _init_state_dir
  printf '%s' "$STATE_DIR/timings.json"
}
