#!/usr/bin/env bash
# lib/core/capabilities.sh - System capability detection
# sysmaint library
# Copyright (c) 2025 Mohamed Elharery

# Functions:
#   detect_capabilities_and_mode() - Auto-detect available tools and system mode
#   _skip_cap()                    - Check if a capability should be skipped
#   _is_root_user()                - Check if running as actual root user

# This module detects what tools and capabilities are available on the system
# (snap, flatpak, fwupd, docker, etc.) and determines if the system is running
# in desktop or server mode.

# Capabilities are stored in:
#   CAPABILITIES_AVAILABLE[]   - Array of available tools
#   CAPABILITIES_UNAVAILABLE[] - Array of missing tools
#   SYSTEM_MODE               - "desktop" or "server"

_is_root_user() {
  [[ $EUID -eq 0 ]]
}

_skip_cap() {
  # Record phase:capability for later analysis
  local pair="$1"
  local found=false
  for sc in "${SKIPPED_CAPABILITIES[@]}"; do
    [[ "$sc" == "$pair" ]] && found=true && break
  done
  [[ "$found" == "false" ]] && SKIPPED_CAPABILITIES+=("$pair")
}

detect_capabilities_and_mode() {
  log "Detecting system capabilities..."
  CAPABILITIES_AVAILABLE=()
  CAPABILITIES_UNAVAILABLE=()

  # Capability checks: common tools, package managers, firmware updater, etc.
  if command -v snap &>/dev/null; then
    CAPABILITIES_AVAILABLE+=("snap")
  else
    CAPABILITIES_UNAVAILABLE+=("snap")
  fi

  if command -v flatpak &>/dev/null; then
    CAPABILITIES_AVAILABLE+=("flatpak")
  else
    CAPABILITIES_UNAVAILABLE+=("flatpak")
  fi

  if command -v fwupdmgr &>/dev/null; then
    CAPABILITIES_AVAILABLE+=("fwupd")
  else
    CAPABILITIES_UNAVAILABLE+=("fwupd")
  fi

  if command -v docker &>/dev/null; then
    CAPABILITIES_AVAILABLE+=("docker")
  else
    CAPABILITIES_UNAVAILABLE+=("docker")
  fi

  if command -v fstrim &>/dev/null; then
    CAPABILITIES_AVAILABLE+=("fstrim")
  else
    CAPABILITIES_UNAVAILABLE+=("fstrim")
  fi

  # Desktop environment detection: DISPLAY or XDG_CURRENT_DESKTOP
  if [[ -n "${DISPLAY:-}" || -n "${XDG_CURRENT_DESKTOP:-}" ]]; then
    DESKTOP_MODE="desktop"
  else
    # Fallback: check for ubuntu-desktop or gnome-shell
    if dpkg -l ubuntu-desktop 2>/dev/null | grep -q "^ii" || \
       dpkg -l gnome-shell 2>/dev/null | grep -q "^ii"; then
      DESKTOP_MODE="desktop"
    else
      DESKTOP_MODE="server"
    fi
  fi

  log "Capability detection: available=${CAPABILITIES_AVAILABLE[*]} unavailable=${CAPABILITIES_UNAVAILABLE[*]} mode=$DESKTOP_MODE guard=$DESKTOP_GUARD_ENABLED"
}
