#!/bin/bash
#
# Health check script for OCTALUM-PULSE
#

set -e

PULSE_BIN="${PULSE_BIN:-/usr/local/bin/pulse}"
TIMEOUT="${TIMEOUT:-30}"

check_binary() {
    if [ ! -x "$PULSE_BIN" ]; then
        echo "ERROR: pulse binary not found at $PULSE_BIN"
        exit 1
    fi
}

check_health() {
    echo "Running health check..."
    
    if ! timeout "$TIMEOUT" "$PULSE_BIN" doctor --quick 2>&1; then
        echo "ERROR: Health check failed"
        exit 1
    fi
    
    echo "Health check passed"
}

check_platform() {
    echo "Checking platform..."
    
    if [ ! -f /etc/os-release ]; then
        echo "ERROR: Cannot detect OS"
        exit 1
    fi
    
    . /etc/os-release
    echo "Platform: $ID $VERSION_ID"
}

check_permissions() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "WARNING: Not running as root, some checks may fail"
    fi
}

main() {
    echo "=== OCTALUM-PULSE Health Check ==="
    echo ""
    
    check_binary
    check_platform
    check_permissions
    check_health
    
    echo ""
    echo "=== All checks passed ==="
}

main "$@"
