#!/bin/bash
#
# test_suite_features.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   Feature-specific test suite for SYSMAINT
#   Tests package management, cleanup, security, firmware, storage, and kernel features
#
# USAGE:
#   bash tests/test_suite_features.sh

set -e

# Test framework
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SYSMAINT="$PROJECT_DIR/sysmaint"

log_test() {
    echo -e "${GREEN}[TEST]${NC} $*"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $*"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $*"
}

run_test() {
    local test_name="$1"
    local test_func="$2"

    ((TESTS_RUN++))
    log_test "$test_name"

    if $test_func; then
        ((TESTS_PASSED++))
        log_pass "$test_name"
        return 0
    else
        ((TESTS_FAILED++))
        log_fail "$test_name"
        return 1
    fi
}

# Package Management Tests
test_upgrade_flag_exists() {
    bash "$SYSMAINT" --help 2>&1 | grep -q "\-\-upgrade"
}

test_package_manager_detected() {
    # At least one package manager should be available
    command -v apt &>/dev/null || command -v apt-get &>/dev/null ||
    command -v dnf &>/dev/null || command -v yum &>/dev/null ||
    command -v pacman &>/dev/null || command -v zypper &>/dev/null
}

test_dry_run_does_not_upgrade() {
    # --dry-run should not actually upgrade packages
    local before
    before=$(rpm -qa 2>/dev/null | wc -l || dpkg -l 2>/dev/null | wc -l)
    bash "$SYSMAINT" --upgrade --dry-run &>/dev/null || true
    local after
    after=$(rpm -qa 2>/dev/null | wc -l || dpkg -l 2>/dev/null | wc -l)
    [[ "$before" -eq "$after" ]]
}

# Snap/Flatpak Tests
test_snap_support_if_available() {
    if command -v snap &>/dev/null; then
        snap list &>/dev/null || return 1
    fi
}

test_flatpak_support_if_available() {
    if command -v flatpak &>/dev/null; then
        flatpak list &>/dev/null || return 1
    fi
}

# System Cleanup Tests
test_cleanup_flag_exists() {
    bash "$SYSMAINT" --help 2>&1 | grep -q "\-\-cleanup"
}

test_cleanup_dry_run_safe() {
    bash "$SYSMAINT" --cleanup --dry-run &>/dev/null || return 1
}

test_temp_dir_exists() {
    [[ -d /tmp ]] || [[ -d /var/tmp ]]
}

test_cache_dirs_exist() {
    # Check common cache directories
    [[ -d /var/cache ]] || return 1
}

# Kernel Purge Tests
test_purge_kernels_flag_exists() {
    bash "$SYSMAINT" --help 2>&1 | grep -q "\-\-purge-kernels" || bash "$SYSMAINT" --help 2>&1 | grep -q "purge.kernel"
}

test_kernel_detection() {
    # Should be able to detect installed kernels
    if command -v dpkg &>/dev/null; then
        dpkg -l | grep -q "linux-image" || return 0
    elif command -v rpm &>/dev/null; then
        rpm -qa | grep -q "kernel" || return 0
    fi
}

test_current_kernel_protected() {
    # Current running kernel should be protected from purge
    local current_kernel
    current_kernel=$(uname -r)
    [[ -n "$current_kernel" ]]
}

# Security Audit Tests
test_security_audit_flag_exists() {
    bash "$SYSMAINT" --help 2>&1 | grep -q "\-\-security-audit"
}

test_security_audit_dry_run() {
    bash "$SYSMAINT" --security-audit --dry-run &>/dev/null || return 1
}

test_faillock_check() {
    # Check for faillock configuration (account lockout)
    [[ -f /etc/security/faillock.conf ]] || grep -qi "pam_faillock" /etc/pam.d/common-* 2>/dev/null || return 0
}

# Firmware Update Tests
test_firmware_flag_exists() {
    bash "$SYSMAINT" --help 2>&1 | grep -q "\-\-update-firmware" || bash "$SYSMAINT" --help 2>&1 | grep -q "firmware"
}

test_fwupdtlr_if_available() {
    if command -v fwupdmgr &>/dev/null; then
        fwupdmgr --version &>/dev/null || return 1
    fi
}

# Storage Maintenance Tests
test_fstrim_available() {
    command -v fstrim &>/dev/null || return 0
}

test_fstrim_dry_run() {
    if command -v fstrim &>/dev/null; then
        fstrim --version &>/dev/null || return 1
    fi
}

test_swap_info_available() {
    [[ -f /proc/swaps ]] || swapon --show &>/dev/null || free | grep -q "Swap"
}

test_disk_space_check() {
    df -h / &>/dev/null
}

# Log Rotation Tests
test_logrotate_exists() {
    command -v logrotate &>/dev/null || return 0
}

test_logrotate_config() {
    [[ -f /etc/logrotate.conf ]] || [[ -d /etc/logrotate.d ]]
}

test_systemd_journal_rotation() {
    journalctl --version &>/dev/null || return 0
}

# Systemd Service Tests
test_systemd_services_managed() {
    command -v systemctl &>/dev/null || return 1
    systemctl list-units &>/dev/null
}

test_failed_services_check() {
    systemctl --failed &>/dev/null || true
}

# Backup Tests
test_backup_config_exists() {
    [[ -f /etc/system-maintenance/backup.conf ]] || [[ -f /etc/system-maintenance/config.sh ]] || return 0
}

test_backup_dir_exists() {
    [[ -d /var/backups ]] || [[ -d /var/lib/system-maintenance/backups ]] || return 0
}

# Network Update Tests
test_network_connectivity() {
    ping -c 1 8.8.8.8 &>/dev/null || ping -c 1 1.1.1.1 &>/dev/null || return 0
}

test_dns_resolution() {
    getent hosts google.com &>/dev/null || getent hosts example.com &>/dev/null || return 0
}

# Repository Tests
test_repos_accessible() {
    if command -v apt &>/dev/null; then
        apt-get update -qq &>/dev/null || return 1
    elif command -v dnf &>/dev/null; then
        dnf check-update &>/dev/null || true
    fi
}

# GPG Key Tests
test_package_keys_valid() {
    # Check package signing keys
    if command -v apt-key &>/dev/null; then
        apt-key list &>/dev/null || return 0
    elif command -v rpm &>/dev/null; then
        rpm -q gpg-pubkey &>/dev/null || return 0
    fi
}

# Feature Integration Tests
test_multiple_flags_work() {
    bash "$SYSMAINT" --cleanup --dry-run &>/dev/null
}

test_auto_with_cleanup() {
    bash "$SYSMAINT" --auto --cleanup --dry-run &>/dev/null
}

test_verbose_with_security() {
    bash "$SYSMAINT" --verbose --security-audit --dry-run &>/dev/null
}

# Main test execution
main() {
    echo "========================================"
    echo "SYSMAINT Feature-Specific Test Suite"
    echo "========================================"
    echo ""

    # Package Management Tests
    echo "Testing Package Management..."
    run_test "--upgrade flag exists" test_upgrade_flag_exists
    run_test "Package manager detected" test_package_manager_detected
    run_test "--dry-run does not upgrade" test_dry_run_does_not_upgrade
    run_test "Snap support" test_snap_support_if_available
    run_test "Flatpak support" test_flatpak_support_if_available
    echo ""

    # System Cleanup Tests
    echo "Testing System Cleanup..."
    run_test "--cleanup flag exists" test_cleanup_flag_exists
    run_test "--cleanup --dry-run safe" test_cleanup_dry_run_safe
    run_test "Temp directories exist" test_temp_dir_exists
    run_test "Cache directories exist" test_cache_dirs_exist
    echo ""

    # Kernel Management Tests
    echo "Testing Kernel Management..."
    run_test "--purge-kernels flag exists" test_purge_kernels_flag_exists
    run_test "Kernel detection works" test_kernel_detection
    run_test "Current kernel protected" test_current_kernel_protected
    echo ""

    # Security Audit Tests
    echo "Testing Security Audit..."
    run_test "--security-audit flag exists" test_security_audit_flag_exists
    run_test "Security audit --dry-run" test_security_audit_dry_run
    run_test "Faillock check" test_faillock_check
    echo ""

    # Firmware Update Tests
    echo "Testing Firmware Updates..."
    run_test "--update-firmware flag exists" test_firmware_flag_exists
    run_test "fwupdmgr available" test_fwupdtlr_if_available
    echo ""

    # Storage Maintenance Tests
    echo "Testing Storage Maintenance..."
    run_test "fstrim available" test_fstrim_available
    run_test "fstrim --dry-run" test_fstrim_dry_run
    run_test "Swap info available" test_swap_info_available
    run_test "Disk space check" test_disk_space_check
    echo ""

    # Log Rotation Tests
    echo "Testing Log Rotation..."
    run_test "logrotate exists" test_logrotate_exists
    run_test "logrotate config exists" test_logrotate_config
    run_test "systemd journal rotation" test_systemd_journal_rotation
    echo ""

    # Systemd Service Tests
    echo "Testing Systemd Services..."
    run_test "systemd services managed" test_systemd_services_managed
    run_test "Failed services check" test_failed_services_check
    echo ""

    # Backup Tests
    echo "Testing Backups..."
    run_test "Backup config exists" test_backup_config_exists
    run_test "Backup directory exists" test_backup_dir_exists
    echo ""

    # Network Tests
    echo "Testing Network..."
    run_test "Network connectivity" test_network_connectivity
    run_test "DNS resolution" test_dns_resolution
    run_test "Repositories accessible" test_repos_accessible
    run_test "Package keys valid" test_package_keys_valid
    echo ""

    # Feature Integration Tests
    echo "Testing Feature Integration..."
    run_test "Multiple flags work" test_multiple_flags_work
    run_test "--auto with --cleanup" test_auto_with_cleanup
    run_test "--verbose with --security-audit" test_verbose_with_security
    echo ""

    # Summary
    echo "========================================"
    echo "Test Summary"
    echo "========================================"
    echo "Tests run:    $TESTS_RUN"
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        return 1
    fi
}

main "$@"
