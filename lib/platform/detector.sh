#!/usr/bin/env bash
# Platform Detector Module
# Automatically detects and loads the appropriate platform module
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery

# Directory where platform modules are stored
PLATFORM_LIB_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Currently loaded platform
_CURRENT_PLATFORM_MODULE=""
_CURRENT_PLATFORM_NAME=""

# List of available platform modules (in priority order)
_PLATFORM_MODULES=(
    "debian.sh"     # Debian/Ubuntu (test first as it's most common)
    "redhat.sh"     # RedHat family
    "arch.sh"       # Arch family
    "suse.sh"       # SUSE family
)

# -----------------------------------------------------------------------------
# Platform Detection
# -----------------------------------------------------------------------------

# Detect current platform and return the module filename
detect_platform_module() {
    for module in "${_PLATFORM_MODULES[@]}"; do
        # Source the module to get its platform_detect function
        # shellcheck source=lib/platform/base.sh
        . "$PLATFORM_LIB_DIR/$module" 2>/dev/null || continue

        # Call platform_detect function
        if platform_detect 2>/dev/null; then
            echo "$module"
            return 0
        fi
    done

    # No specific platform detected, use base
    echo "base.sh"
    return 0
}

# Load the appropriate platform module
load_platform_module() {
    local module="${1:-$(detect_platform_module)}"
    local module_path="$PLATFORM_LIB_DIR/$module"

    if [ ! -f "$module_path" ]; then
        echo "ERROR: Platform module not found: $module_path" >&2
        return 1
    fi

    # Source the module
    # shellcheck source=lib/platform/base.sh
    . "$module_path" || return 1

    # Initialize the platform
    if declare -f platform_init >/dev/null 2>&1; then
        platform_init
    fi

    _CURRENT_PLATFORM_MODULE="$module"
    _CURRENT_PLATFORM_NAME="$(platform_name 2>/dev/null || echo "unknown")"

    log "Platform module loaded: $module ($(_CURRENT_PLATFORM_NAME))"
    return 0
}

# Get current platform info
get_platform_name() {
    echo "${_CURRENT_PLATFORM_NAME:-base}"
}

get_platform_family() {
    platform_family 2>/dev/null || echo "unknown"
}

get_platform_module() {
    echo "$_CURRENT_PLATFORM_MODULE"
}

# Reload platform module (useful for testing)
reload_platform_module() {
    _CURRENT_PLATFORM_MODULE=""
    _CURRENT_PLATFORM_NAME=""
    load_platform_module
}

# -----------------------------------------------------------------------------
# Convenience Wrappers
# -----------------------------------------------------------------------------

# Check if platform has a specific quirk
platform_has_quirk_safe() {
    local quirk="$1"

    if declare -f platform_has_quirk >/dev/null 2>&1; then
        platform_has_quirk "$quirk"
    else
        return 1
    fi
}

# Get platform quirks safely
platform_get_quirks() {
    if declare -f platform_quirks >/dev/null 2>&1; then
        platform_quirks
    else
        echo ""
    fi
}

# Check dependencies safely
platform_check_deps_safe() {
    if declare -f platform_check_dependencies >/dev/null 2>&1; then
        platform_check_dependencies
    else
        return 0
    fi
}

# -----------------------------------------------------------------------------
# Auto-Load on Source
# -----------------------------------------------------------------------------

# Automatically load the detected platform module when this file is sourced
# Set SKIP_PLATFORM_AUTOLOAD=1 to disable auto-loading
if [ "${SKIP_PLATFORM_AUTOLOAD:-0}" != "1" ]; then
    load_platform_module
fi

# Export functions
export -f detect_platform_module
export -f load_platform_module
export -f get_platform_name
export -f get_platform_family
export -f get_platform_module
export -f reload_platform_module
export -f platform_has_quirk_safe
export -f platform_get_quirks
export -f platform_check_deps_safe

# Export variables
export _CURRENT_PLATFORM_MODULE
export _CURRENT_PLATFORM_NAME
export _PLATFORM_MODULES
