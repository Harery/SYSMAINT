#!/usr/bin/env bash
# Debian/Ubuntu Platform Module
# Handles Debian and Ubuntu distributions
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery

# Load base module first
# shellcheck source=lib/platform/base.sh
. "$(dirname "${BASH_SOURCE[0]}")/base.sh"

# Platform identification
_PLATFORM_NAME="debian"
_PLATFORM_FAMILY="debian"
_SUPPORTED=true

# Debian-specific versions
_DEBIAN_VERSIONS=("ubuntu" "debian")

# -----------------------------------------------------------------------------
# Platform Detection
# -----------------------------------------------------------------------------

platform_detect() {
    if [ -f /etc/os-release ]; then
        local id
        id=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')

        case "$id" in
            ubuntu|debian)
                return 0
                ;;
        esac
    fi
    return 1
}

# -----------------------------------------------------------------------------
# Dependency Checking
# -----------------------------------------------------------------------------

platform_check_dependencies() {
    # Debian/Ubuntu has all required tools by default
    command -v flock >/dev/null 2>&1 || {
        log "WARNING: flock not found. Installing util-linux..."
        sudo apt-get install -y util-linux >/dev/null 2>&1 || return 1
    }
    command -v bc >/dev/null 2>&1 || {
        log "WARNING: bc not found. Installing bc..."
        sudo apt-get install -y bc >/dev/null 2>&1 || return 1
    }
    return 0
}

# -----------------------------------------------------------------------------
# Package Manager Commands
# -----------------------------------------------------------------------------

platform_update_cmd() {
    echo "apt-get update"
}

platform_upgrade_cmd() {
    echo "apt-get upgrade -y"
}

platform_autoremove_cmd() {
    echo "apt-get autoremove -y"
}

# -----------------------------------------------------------------------------
# Initialization
# -----------------------------------------------------------------------------

platform_init() {
    log "Debian/Ubuntu platform initialized"
    log "Using APT package manager"
}

# Export functions
export -f platform_detect
export -f platform_check_dependencies
export -f platform_update_cmd
export -f platform_upgrade_cmd
export -f platform_autoremove_cmd
export -f platform_init
