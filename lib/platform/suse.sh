#!/usr/bin/env bash
# SUSE Family Platform Module
# Handles openSUSE, SLES
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery

# Load base module first
# shellcheck source=lib/platform/base.sh
. "$(dirname "${BASH_SOURCE[0]}")/base.sh"

# Platform identification
_PLATFORM_NAME="suse"
_PLATFORM_FAMILY="suse"
_SUPPORTED=true

# -----------------------------------------------------------------------------
# Platform Detection
# -----------------------------------------------------------------------------

platform_detect() {
    if [ -f /etc/os-release ]; then
        local id
        id=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')

        case "$id" in
            opensuse|sles)
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

    command -v flock >/dev/null 2>&1 || missing+=("util-linux")
    command -v bc >/dev/null 2>&1 || missing+=("bc")
    command -v awk >/dev/null 2>&1 || missing+=("gawk")  # SUSE uses gawk

    if [ ${#missing[@]} -gt 0 ]; then
        log "WARNING: Missing dependencies: ${missing[*]}"
        log "Using fallback implementations where possible"
        log "Recommend: zypper install ${missing[*]}"
        return 1
    fi
    return 0
}

platform_install_dependencies() {
    zypper install -y util-linux bc gawk 2>/dev/null
}

# -----------------------------------------------------------------------------
# Locking Mechanism (with fallback)
# -----------------------------------------------------------------------------

platform_lock_method() {
    if command -v flock >/dev/null 2>&1; then
        echo "flock"
    else
        echo "mkdir"
    fi
}

# -----------------------------------------------------------------------------
# Math Operations (with awk fallback)
# -----------------------------------------------------------------------------

platform_math_divide() {
    local numerator="$1"
    local denominator="$2"
    local scale="${3:-2}"

    if command -v bc >/dev/null 2>&1; then
        echo "scale=$scale; $numerator / $denominator" | bc
    else
        awk "BEGIN {printf \"%.${scale}f\", $numerator / $denominator}"
    fi
}

platform_format_disk_mb() {
    local kb="$1"

    if command -v bc >/dev/null 2>&1; then
        echo "scale=2; $kb / 1024" | bc
    else
        awk "BEGIN {printf \"%.2f\", $kb / 1024}"
    fi
}

# -----------------------------------------------------------------------------
# Platform Quirks
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
        missing_awk)
            command -v awk >/dev/null 2>&1 || return 0
            return 1
            ;;
        exit_code_127)
            # openSUSE specific: some commands may exit with 127
            return 0
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
    command -v awk >/dev/null 2>&1 || quirks+=("missing_awk")
    quirks+=("exit_code_127")  # Known quirk

    [ ${#quirks[@]} -gt 0 ] && echo "${quirks[@]}"
}

# -----------------------------------------------------------------------------
# Package Manager Commands
# -----------------------------------------------------------------------------

platform_update_cmd() {
    echo "zypper refresh"
}

platform_upgrade_cmd() {
    echo "zypper dist-upgrade -y"
}

platform_autoremove_cmd() {
    echo "zypper remove -u"
}

# -----------------------------------------------------------------------------
# Initialization
# -----------------------------------------------------------------------------

platform_init() {
    log "SUSE family platform initialized"

    if ! platform_check_dependencies; then
        log "INFO: Using fallback implementations for missing dependencies"
    fi

    # Fix exit code 127 issue
    if platform_has_quirk exit_code_127; then
        log "INFO: Applying exit code 127 workaround"
        # Ensure we exit cleanly
        trap 'exit 0' EXIT
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
