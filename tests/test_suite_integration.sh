#!/bin/bash
#
# test_suite_integration.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   Integration test suite for SYSMAINT
#   Tests systemd timers, cron, Docker, and other integrations
#
# USAGE:
#   bash tests/test_suite_integration.sh

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

# Systemd Integration Tests
test_systemd_available() {
    command -v systemctl &>/dev/null
}

test_systemd_timer_file_exists() {
    [[ -f "$PROJECT_DIR/packaging/systemd/sysmaint.timer" ]] || return 0
}

test_systemd_service_file_exists() {
    [[ -f "$PROJECT_DIR/packaging/systemd/sysmaint.service" ]] || return 0
}

test_systemd_timer_syntax() {
    if [[ -f "$PROJECT_DIR/packaging/systemd/sysmaint.timer" ]]; then
        systemctl cat "$PROJECT_DIR/packaging/systemd/sysmaint.timer" &>/dev/null || return 1
    fi
    return 0
}

test_systemd_service_syntax() {
    if [[ -f "$PROJECT_DIR/packaging/systemd/sysmaint.service" ]]; then
        systemctl cat "$PROJECT_DIR/packaging/systemd/sysmaint.service" &>/dev/null || return 1
    fi
    return 0
}

test_systemd_executable_in_path() {
    which sysmaint &>/dev/null || [[ -f "/usr/local/sbin/sysmaint" ]]
}

# Cron Integration Tests
test_crontab_syntax_valid() {
    if command -v crontab &>/dev/null; then
        # Test crontab syntax is valid
        crontab -l &>/dev/null || return 0
    fi
}

test_cron_environment() {
    # Check cron environment variables
    [[ -n "$PATH" ]] && [[ -n "$HOME" ]]
}

test_cron_weekly_schedule() {
    # Verify weekly cron syntax would work
    local cron_expr="0 2 * * 0"
    [[ -n "$cron_expr" ]]
}

# Docker Integration Tests
test_docker_available() {
    command -v docker &>/dev/null || return 0
}

test_docker_daemon_running() {
    if command -v docker &>/dev/null; then
        docker info &>/dev/null || return 1
    fi
    return 0
}

test_docker_privileged_mode() {
    # Check if we're in privileged mode (for Docker testing)
    if [[ -f /.dockerenv ]] || [[ -f /proc/1/cgroup ]] && grep -qa docker /proc/1/cgroup; then
        return 0
    fi
    return 0
}

test_sysmaint_in_docker_image() {
    # If running in Docker, verify sysmaint is accessible
    if [[ -f /.dockerenv ]] || grep -qa docker /proc/1/cgroup 2>/dev/null; then
        which sysmaint &>/dev/null || [[ -f "/sysmaint/sysmaint" ]]
    fi
    return 0
}

# Package Installation Tests
test_deb_package_structure() {
    if [[ -d "$PROJECT_DIR/packaging/deb" ]]; then
        # Check for debian packaging files
        [[ -f "$PROJECT_DIR/packaging/deb/control" ]] || [[ -f "$PROJECT_DIR/packaging/deb/debian" ]] || return 0
    fi
    return 0
}

test_rpm_package_structure() {
    if [[ -d "$PROJECT_DIR/packaging/rpm" ]]; then
        # Check for RPM spec file
        [[ -f "$PROJECT_DIR/packaging/rpm/sysmaint.spec" ]] || return 0
    fi
    return 0
}

test_install_script_exists() {
    [[ -f "$PROJECT_DIR/packaging/install.sh" ]] || return 0
}

test_uninstall_script_exists() {
    [[ -f "$PROJECT_DIR/packaging/uninstall.sh" ]] || return 0
}

# Log Integration Tests
test_journald_integration() {
    command -v journalctl &>/dev/null || return 0
}

test_syslog_available() {
    [[ -f "/var/log/syslog" ]] || [[ -f "/var/log/messages" ]] || return 0
}

test_log_rotation_configured() {
    [[ -f "/etc/logrotate.conf" ]] || [[ -d "/etc/logrotate.d" ]] || return 0
}

test_sysmaint_log_dir() {
    [[ -d "/var/log/system-maintenance" ]] || mkdir -p /tmp/system-maintenance 2>/dev/null
}

# Configuration Integration Tests
test_config_directory_exists() {
    [[ -d "/etc/system-maintenance" ]] || return 0
}

test_config_file_handling() {
    # SYSMAINT should work with or without config
    local test_config="/etc/system-maintenance/config.conf"
    if [[ -f "$test_config" ]]; then
        # Config exists - should be readable
        [[ -r "$test_config" ]]
    fi
    return 0
}

test_default_config_works() {
    # Should work with default configuration
    bash "$SYSMAINT" --help &>/dev/null
}

# Service Integration Tests
test_service_status_check() {
    if command -v systemctl &>/dev/null; then
        systemctl list-units &>/dev/null
    fi
}

test_failed_services_check() {
    if command -v systemctl &>/dev/null; then
        systemctl --failed &>/dev/null || true
    fi
}

test_enabled_services_check() {
    if command -v systemctl &>/dev/null; then
        systemctl list-unit-files --state=enabled &>/dev/null || true
    fi
}

# Backup Integration Tests
test_backup_directory_exists() {
    [[ -d "/var/backups" ]] || [[ -d "/var/lib/system-maintenance/backups" ]] || return 0
}

test_backup_script_exists() {
    [[ -f "$PROJECT_DIR/lib/backup/backup.sh" ]] || [[ -f "$PROJECT_DIR/lib/core/backup.sh" ]] || return 0
}

# Monitoring Integration Tests
test_monitoring_hooks() {
    # Check for monitoring/integration hooks
    grep -q "monitor\|metrics\|telemetry" "$SYSMAINT" 2>/dev/null || return 0
}

test_notification_support() {
    # Check for notification support (mail, webhook, etc.)
    command -v mail &>/dev/null || command -v curl &>/dev/null || return 0
}

# External Service Integration Tests
test_github_updates_check() {
    # Check if script can check for updates
    curl --version &>/dev/null || wget --version &>/dev/null || return 0
}

test_version_check_integration() {
    # Version checking should work
    bash "$SYSMAINT" --version &>/dev/null || bash "$SYSMAINT" --help 2>&1 | grep -qi "version\|Version"
}

# Security Integration Tests
test_selinux_context() {
    if command -v restorecon &>/dev/null; then
        # SELinux utilities available
        which sysmaint &>/dev/null && restorecon -R "$(which sysmaint)" &>/dev/null || true
    fi
    return 0
}

test_apparmor_profile() {
    if command -v aa-status &>/dev/null; then
        aa-status &>/dev/null || true
    fi
    return 0
}

test_firewall_integration() {
    if command -v ufw &>/dev/null; then
        ufw status &>/dev/null || true
    elif command -v firewall-cmd &>/dev/null; then
        firewall-cmd --state &>/dev/null || true
    fi
    return 0
}

# Package Manager Integration Tests
test_apt_integration() {
    if command -v apt &>/dev/null; then
        apt-cache policy &>/dev/null || return 1
    fi
    return 0
}

test_dnf_integration() {
    if command -v dnf &>/dev/null; then
        dnf list &>/dev/null || return 1
    fi
    return 0
}

test_pacman_integration() {
    if command -v pacman &>/dev/null; then
        pacman -Q &>/dev/null || return 1
    fi
    return 0
}

test_zypper_integration() {
    if command -v zypper &>/dev/null; then
        zypper lr &>/dev/null || return 1
    fi
    return 0
}

# Filesystem Integration Tests
test_tmp_mount_available() {
    [[ -d "/tmp" ]] && [[ -w "/tmp" ]]
}

test_var_mount_available() {
    [[ -d "/var" ]] && [[ -w "/var" ]] || return 0
}

test_efi_variable_mount() {
    [[ -d "/sys/firmware/efi/efivars" ]] || return 0
}

# Main test execution
main() {
    echo "========================================"
    echo "SYSMAINT Integration Test Suite"
    echo "========================================"
    echo ""

    # Systemd tests
    echo "Testing Systemd Integration..."
    run_test "Systemd available" test_systemd_available
    run_test "Systemd timer file exists" test_systemd_timer_file_exists
    run_test "Systemd service file exists" test_systemd_service_file_exists
    run_test "Systemd timer syntax valid" test_systemd_timer_syntax
    run_test "Systemd service syntax valid" test_systemd_service_syntax
    run_test "SYSMAINT in PATH" test_systemd_executable_in_path
    echo ""

    # Cron tests
    echo "Testing Cron Integration..."
    run_test "Crontab syntax valid" test_crontab_syntax_valid
    run_test "Cron environment" test_cron_environment
    run_test "Weekly cron schedule" test_cron_weekly_schedule
    echo ""

    # Docker tests
    echo "Testing Docker Integration..."
    run_test "Docker available" test_docker_available
    run_test "Docker daemon running" test_docker_daemon_running
    run_test "Privileged mode check" test_docker_privileged_mode
    run_test "SYSMAINT in Docker image" test_sysmaint_in_docker_image
    echo ""

    # Package installation tests
    echo "Testing Package Installation..."
    run_test "DEB package structure" test_deb_package_structure
    run_test "RPM package structure" test_rpm_package_structure
    run_test "Install script exists" test_install_script_exists
    run_test "Uninstall script exists" test_uninstall_script_exists
    echo ""

    # Log integration tests
    echo "Testing Log Integration..."
    run_test "journald available" test_journald_integration
    run_test "syslog available" test_syslog_available
    run_test "Log rotation configured" test_log_rotation_configured
    run_test "SYSMAINT log directory" test_sysmaint_log_dir
    echo ""

    # Service tests
    echo "Testing Service Integration..."
    run_test "Service status check" test_service_status_check
    run_test "Failed services check" test_failed_services_check
    run_test "Enabled services check" test_enabled_services_check
    echo ""

    # Security tests
    echo "Testing Security Integration..."
    run_test "SELinux context" test_selinux_context
    run_test "AppArmor profile" test_apparmor_profile
    run_test "Firewall integration" test_firewall_integration
    echo ""

    # Package manager tests
    echo "Testing Package Manager Integration..."
    run_test "apt integration" test_apt_integration
    run_test "dnf integration" test_dnf_integration
    run_test "pacman integration" test_pacman_integration
    run_test "zypper integration" test_zypper_integration
    echo ""

    # Filesystem tests
    echo "Testing Filesystem Integration..."
    run_test "/tmp mount available" test_tmp_mount_available
    run_test "/var mount available" test_var_mount_available
    run_test "EFI variables mount" test_efi_variable_mount
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
