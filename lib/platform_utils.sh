#!/usr/bin/env bash
# Platform Utilities Module
# Provides utility functions that use platform modules
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery

# Ensure platform module is loaded
if [ "$(get_platform_module 2>/dev/null)" = "" ]; then
    # shellcheck source=lib/platform/detector.sh
    . "$(dirname "${BASH_SOURCE[0]}")/platform/detector.sh"
fi

# -----------------------------------------------------------------------------
# Disk Usage Formatting (with platform-aware fallbacks)
# -----------------------------------------------------------------------------

# Format disk usage in MB with platform-specific handling
format_disk_mb_safe() {
    local kb="$1"

    # Use platform module if available
    if declare -f platform_format_disk_mb >/dev/null 2>&1; then
        platform_format_disk_mb "$kb"
    else
        # Fallback to awk (most portable)
        awk "BEGIN {printf \"%.2f\", $kb / 1024}"
    fi
}

# Format disk space with "Used" or "Freed" prefix
format_disk_delta() {
    local kb_saved="$1"
    local prefix="${2:-Freed}"

    if [ "$kb_saved" -gt 0 ]; then
        printf '  %s:   %s KB (%.2f MB)\n' \
            "$prefix" \
            "$kb_saved" \
            "$(format_disk_mb_safe "$kb_saved")"
    elif [ "$kb_saved" -lt 0 ]; then
        local kb_used="$((-kb_saved))"
        printf '  %s:   %s KB (%.2f MB)\n' \
            "Used" \
            "$kb_used" \
            "$(format_disk_mb_safe "$kb_used")"
    else
        printf '  No change\n'
    fi
}

# -----------------------------------------------------------------------------
# Lock Management (with platform-aware fallbacks)
# -----------------------------------------------------------------------------

# Initialize lock with platform-specific method
init_lock_safe() {
    local lockfile="$1"

    # Check if platform has lock method detection
    if declare -f platform_lock_method >/dev/null 2>&1; then
        _LOCK_METHOD="$(platform_lock_method)"
        log "Lock method: $_LOCK_METHOD"
    else
        # Fallback detection
        if command -v flock >/dev/null 2>&1; then
            _LOCK_METHOD="flock"
        else
            _LOCK_METHOD="mkdir"
            log "WARNING: flock not found, using mkdir-based locking"
        fi
    fi

    export _LOCK_METHOD
}

# -----------------------------------------------------------------------------
# Compatibility Shims (for existing code)
# -----------------------------------------------------------------------------

# These shims allow existing code to work without changes
# They check if platform module provides the function, otherwise use defaults

if ! declare -f platform_lock_acquire >/dev/null 2>&1; then
    # Provide fallback if platform module doesn't have this function
    platform_lock_acquire() {
        local lockfile="$1"
        local lock_wait="${2:-0}"

        if [ "${_LOCK_METHOD:-flock}" = "flock" ] && command -v flock >/dev/null 2>&1; then
            if [ "$lock_wait" -gt 0 ]; then
                flock -w "$lock_wait" 200 || return 1
            else
                flock 200 || return 1
            fi
        else
            # mkdir-based fallback
            local lock_dir="${lockfile}.dir"
            if [ "$lock_wait" -gt 0 ]; then
                local elapsed=0
                while [ $elapsed -lt "$lock_wait" ]; do
                    if mkdir "$lock_dir" 2>/dev/null; then
                        return 0
                    fi
                    sleep 1
                    ((elapsed++))
                done
                return 1
            else
                while ! mkdir "$lock_dir" 2>/dev/null; do
                    sleep 0.1
                done
            fi
        fi
        return 0
    }
    export -f platform_lock_acquire
fi

if ! declare -f platform_lock_release >/dev/null 2>&1; then
    platform_lock_release() {
        local lockfile="$1"

        if [ "${_LOCK_METHOD:-flock}" = "flock" ] && command -v flock >/dev/null 2>&1; then
            flock -u 200 2>/dev/null || true
            exec 200>&- 2>/dev/null || true
        else
            rm -rf "${lockfile}.dir" 2>/dev/null || true
        fi
    }
    export -f platform_lock_release
fi

# -----------------------------------------------------------------------------
# Platform Quirk Checking
# -----------------------------------------------------------------------------

# Check if we should apply a workaround for a known issue
should_apply_workaround() {
    local issue="$1"

    case "$issue" in
        bc_missing)
            # Check if bc is missing
            command -v bc >/dev/null 2>&1 && return 1 || return 0
            ;;
        flock_missing)
            # Check if flock is missing
            command -v flock >/dev/null 2>&1 && return 1 || return 0
            ;;
        exit_code_127)
            # Check if platform has exit code 127 quirk
            if declare -f platform_has_quirk >/dev/null 2>&1; then
                platform_has_quirk exit_code_127
            else
                return 1
            fi
            ;;
        *)
            # Check platform module
            if declare -f platform_has_quirk >/dev/null 2>&1; then
                platform_has_quirk "$issue"
            else
                return 1
            fi
            ;;
    esac
}

# -----------------------------------------------------------------------------
# Integration Helper
# -----------------------------------------------------------------------------

# Call this to integrate platform modules into existing script
# Usage: source_platform_modules && use_platform_functions
source_platform_modules() {
    local platform_lib_dir
    platform_lib_dir="$(dirname "${BASH_SOURCE[0]}")/platform"

    # Source the detector (which auto-loads the right platform)
    # shellcheck source=lib/platform/detector.sh
    . "$platform_lib_dir/detector.sh"

    log "Platform modules loaded: $(get_platform_module)"
    log "Platform: $(get_platform_name) ($(get_platform_family))"

    # Export platform info for other scripts
    export SYSMAINT_PLATFORM="$(get_platform_name)"
    export SYSMAINT_PLATFORM_FAMILY="$(get_platform_family)"
    export SYSMAINT_PLATFORM_MODULE="$(get_platform_module)"
}

# Export functions
export -f format_disk_mb_safe
export -f format_disk_delta
export -f init_lock_safe
export -f should_apply_workaround
export -f source_platform_modules
