#!/usr/bin/env bash
# RedHat Family Platform Module
# Handles RedHat, Fedora, CentOS, RHEL, Rocky, AlmaLinux
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery

# Load base module first
# shellcheck source=lib/platform/base.sh
. "$(dirname "${BASH_SOURCE[0]}")/base.sh"

# Platform identification
_PLATFORM_NAME="redhat"
_PLATFORM_FAMILY="redhat"
_SUPPORTED=true

# RedHat-specific distributions
_REDHAT_DISTRIBUTIONS=("fedora" "rhel" "centos" "rocky" "almalinux")

# -----------------------------------------------------------------------------
# Platform Detection
# -----------------------------------------------------------------------------

platform_detect() {
    if [ -f /etc/os-release ]; then
        local id
        id=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')

        case "$id" in
            fedora|rhel|centos|rocky|almalinux)
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
    local missing=()

    # Check flock (may be missing in minimal containers)
    command -v flock >/dev/null 2>&1 || missing+=("util-linux")

    # Check bc (may be missing in minimal containers)
    command -v bc >/dev/null 2>&1 || missing+=("bc")

    if [ ${#missing[@]} -gt 0 ]; then
        log "WARNING: Missing dependencies: ${missing[*]}"
        log "Using fallback implementations where available"
        return 1  # Indicate missing but continue
    fi
    return 0
}

platform_install_dependencies() {
    # Try to install missing dependencies
    if command -v dnf >/dev/null 2>&1; then
        dnf install -y util-linux bc 2>/dev/null && return 0
    elif command -v yum >/dev/null 2>&1; then
        yum install -y util-linux bc 2>/dev/null && return 0
    fi
    return 1
}

# -----------------------------------------------------------------------------
# Locking Mechanism (with fallback support)
# -----------------------------------------------------------------------------

platform_lock_method() {
    # RedHat minimal containers may not have flock
    if command -v flock >/dev/null 2>&1; then
        echo "flock"
    else
        echo "mkdir"  # Use mkdir-based fallback
    fi
}

# -----------------------------------------------------------------------------
# Math/Calculation Operations (with awk fallback)
# -----------------------------------------------------------------------------

platform_math_divide() {
    local numerator="$1"
    local denominator="$2"
    local scale="${3:-2}"

    # RedHat minimal containers may not have bc
    if command -v bc >/dev/null 2>&1; then
        echo "scale=$scale; $numerator / $denominator" | bc
    else
        # Fallback to awk (more portable)
        awk "BEGIN {printf \"%.${scale}f\", $numerator / $denominator}"
    fi
}

# -----------------------------------------------------------------------------
# Disk Reporting (with fallback)
# -----------------------------------------------------------------------------

platform_format_disk_mb() {
    local kb="$1"

    if command -v bc >/dev/null 2>&1; then
        echo "scale=2; $kb / 1024" | bc
    else
        awk "BEGIN {printf \"%.2f\", $kb / 1024}"
    fi
}

# -----------------------------------------------------------------------------
# Platform-Specific Quirks
# -----------------------------------------------------------------------------

platform_has_quirk() {
    local quirk="$1"

    case "$quirk" in
        missing_flock)
            command -v flock >/dev/null 2>&1 || return 0
            return 1
            ;;
        missing_bc)
            command -v bc >/dev/null 2>&1 || return 0
            return 1
            ;;
        *)
            return 1
            ;;
    esac
}

platform_quirks() {
    local quirks=()

    command -v flock >/dev/null 2>&1 || quirks+=("missing_flock")
    command -v bc >/dev/null 2>&1 || quirks+=("missing_bc")

    [ ${#quirks[@]} -gt 0 ] && echo "${quirks[@]}"
}

# -----------------------------------------------------------------------------
# Package Manager Commands
# -----------------------------------------------------------------------------

platform_update_cmd() {
    if command -v dnf >/dev/null 2>&1; then
        echo "dnf makecache"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum makecache"
    fi
}

platform_upgrade_cmd() {
    if command -v dnf >/dev/null 2>&1; then
        echo "dnf upgrade -y"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum upgrade -y"
    fi
}

platform_autoremove_cmd() {
    if command -v dnf >/dev/null 2>&1; then
        echo "dnf autoremove -y"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum autoremove -y"
    fi
}

# -----------------------------------------------------------------------------
# Initialization
# -----------------------------------------------------------------------------

platform_init() {
    log "RedHat family platform initialized"

    # Check for missing dependencies and warn
    if ! platform_check_dependencies; then
        log "INFO: Some optional dependencies missing, using fallbacks"
    fi
}

# Export functions
export -f platform_detect
export -f platform_check_dependencies
export -f platform_install_dependencies
export -f platform_lock_method
export -f platform_math_divide
export -f platform_format_disk_mb
export -f platform_has_quirk
export -f platform_quirks
export -f platform_update_cmd
export -f platform_upgrade_cmd
export -f platform_autoremove_cmd
export -f platform_init
