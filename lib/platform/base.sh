#!/usr/bin/env bash
# Base Platform Module
# Provides default implementations for all platforms
# Specific platform modules can override these functions
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery

# Platform identification
_PLATFORM_NAME="base"
_PLATFORM_FAMILY="unknown"
_SUPPORTED=true

# -----------------------------------------------------------------------------
# Platform Detection
# -----------------------------------------------------------------------------

platform_detect() {
    # Returns true if this is the current platform
    return 1  # Base module never matches
}

platform_name() {
    echo "$_PLATFORM_NAME"
}

platform_family() {
    echo "$_PLATFORM_FAMILY"
}

# -----------------------------------------------------------------------------
# Dependency Checking
# -----------------------------------------------------------------------------

platform_check_dependencies() {
    # Default: check for common dependencies
    local missing=()

    command -v flock >/dev/null 2>&1 || missing+=("flock")
    command -v bc >/dev/null 2>&1 || missing+=("bc")

    if [ ${#missing[@]} -gt 0 ]; then
        log "WARNING: Missing dependencies: ${missing[*]}"
        return 1
    fi
    return 0
}

platform_install_dependencies() {
    # Default: no auto-install (requires root)
    log "Cannot auto-install dependencies. Please install manually."
    return 1
}

# -----------------------------------------------------------------------------
# Locking Mechanism
# -----------------------------------------------------------------------------

# Lock method: "flock" (default) or "mkdir" (fallback)
platform_lock_method() {
    if command -v flock >/dev/null 2>&1; then
        echo "flock"
    else
        echo "mkdir"
    fi
}

# Acquire lock (blocking)
platform_lock_acquire() {
    local lockfile="$1"
    local lock_wait="${2:-0}"

    if [ "$(platform_lock_method)" = "flock" ]; then
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

# Release lock
platform_lock_release() {
    local lockfile="$1"

    if [ "$(platform_lock_method)" = "flock" ]; then
        flock -u 200 2>/dev/null || true
        exec 200>&- 2>/dev/null || true
    else
        rm -rf "${lockfile}.dir" 2>/dev/null || true
    fi
}

# -----------------------------------------------------------------------------
# Math/Calculation Operations
# -----------------------------------------------------------------------------

# Division with decimal result
platform_math_divide() {
    local numerator="$1"
    local denominator="$2"
    local scale="${3:-2}"

    if command -v bc >/dev/null 2>&1; then
        echo "scale=$scale; $numerator / $denominator" | bc
    elif command -v awk >/dev/null 2>&1; then
        # Fallback to awk (more portable than bc)
        awk "BEGIN {printf \"%.${scale}f\", $numerator / $denominator}"
    else
        # Last resort: integer division with bash
        local result=$((numerator / denominator))
        local remainder=$((numerator % denominator))
        # Add one decimal place using remainder
        local decimal=$((remainder * 10 / denominator))
        echo "${result}.${decimal}"
    fi
}

# -----------------------------------------------------------------------------
# Disk Reporting
# -----------------------------------------------------------------------------

platform_format_disk_mb() {
    local kb="$1"
    platform_math_divide "$kb" 1024
}

platform_format_disk_human() {
    local kb="$1"
    local mb=$(platform_math_divide "$kb" 1024 0)

    if [ "$mb" -ge 1024 ]; then
        local gb=$(platform_math_divide "$mb" 1024 1)
        echo "${gb} GB"
    else
        echo "${mb} MB"
    fi
}

# -----------------------------------------------------------------------------
# Platform-Specific Quirks
# -----------------------------------------------------------------------------

# Returns true if platform requires special handling
platform_has_quirk() {
    local quirk="$1"
    return 1  # Base has no quirks
}

# Get list of platform quirks
platform_quirks() {
    echo ""
}

# -----------------------------------------------------------------------------
# Package Manager Commands (defaults - override in platform modules)
# -----------------------------------------------------------------------------

platform_update_cmd() {
    echo "echo 'No update command defined'"
}

platform_upgrade_cmd() {
    echo "echo 'No upgrade command defined'"
}

platform_autoremove_cmd() {
    echo "echo 'No autoremove command defined'"
}

# -----------------------------------------------------------------------------
# Service Management (defaults)
# -----------------------------------------------------------------------------

platform_service_running() {
    local service="$1"
    systemctl is-active --quiet "$service" 2>/dev/null
}

platform_service_enabled() {
    local service="$1"
    systemctl is-enabled --quiet "$service" 2>/dev/null
}

# -----------------------------------------------------------------------------
# Initialization
# -----------------------------------------------------------------------------

platform_init() {
    # Called after platform is loaded
    :
}

# Export functions
export -f platform_detect
export -f platform_name
export -f platform_family
export -f platform_check_dependencies
export -f platform_install_dependencies
export -f platform_lock_method
export -f platform_lock_acquire
export -f platform_lock_release
export -f platform_math_divide
export -f platform_format_disk_mb
export -f platform_format_disk_human
export -f platform_has_quirk
export -f platform_quirks
export -f platform_update_cmd
export -f platform_upgrade_cmd
export -f platform_autoremove_cmd
export -f platform_service_running
export -f platform_service_enabled
export -f platform_init
