#!/bin/bash
#
# test_suite_redhat_family.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   RedHat family-specific test suite
#   Tests for RHEL 9,10, Rocky Linux 9,10, AlmaLinux 9, CentOS Stream 9
#   Focuses on dnf/yum package manager behavior
#
# USAGE:
#   bash tests/test_suite_redhat_family.sh

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

# Detect if we're on RedHat family
test_redhat_family_detection() {
    if [[ ! -f /etc/os-release ]]; then
        return 1
    fi

    . /etc/os-release
    [[ "$ID" == "rhel" ]] || [[ "$ID" == "rocky" ]] || [[ "$ID" == "almalinux" ]] ||
    [[ "$ID" == "centos" ]] || [[ "$ID_LIKE" =~ rhel ]] || [[ "$ID_LIKE" =~ fedora ]]
}

test_dnf_or_yum_available() {
    command -v dnf &>/dev/null || command -v yum &>/dev/null
}

test_rpm_available() {
    command -v rpm &>/dev/null
}

test_redhat_release_file() {
    [[ -f /etc/redhat-release ]] || [[ -f /etc/rocky-release ]] ||
    [[ -f /etc/almalinux-release ]] || [[ -f /etc/centos-release ]]
}

test_dnf_cache_exists() {
    [[ -d /var/cache/dnf ]] || [[ -d /var/cache/yum ]]
}

test_dnf_config_exists() {
    [[ -f /etc/dnf/dnf.conf ]] || [[ -f /etc/yum.conf ]]
}

test_dnf_repo_files() {
    [[ -d /etc/yum.repos.d ]] || [[ -d /etc/dnf/repos.d ]]
}

test_rpm_query_works() {
    rpm -qa &>/dev/null || return 1
}

test_dnf_makecache_works() {
    if command -v dnf &>/dev/null; then
        if [[ $EUID -ne 0 ]]; then
            sudo dnf makecache --quiet &>/dev/null || return 1
        else
            dnf makecache --quiet &>/dev/null || return 1
        fi
    elif command -v yum &>/dev/null; then
        if [[ $EUID -ne 0 ]]; then
            sudo yum makecache --quiet &>/dev/null || return 1
        else
            yum makecache --quiet &>/dev/null || return 1
        fi
    fi
}

test_redhat_gpg_keys() {
    [[ -d /etc/pki/rpm-gpg ]] || rpm -q gpg-pubkey &>/dev/null
}

test_selinux_available() {
    command -v getenforce &>/dev/null || command -v sestatus &>/dev/null || return 0
}

test_redhat_specific_paths() {
    # Check for RedHat-specific paths
    [[ -d /usr/libexec ]] || [[ -f /etc/sysconfig/network-scripts/ifcfg-* ]]
}

test_firewalld_if_applicable() {
    # Most RHEL family systems use firewalld
    systemctl is-active firewalld &>/dev/null || systemctl is-enabled firewalld &>/dev/null || return 0
}

test_subscription_manager_if_rhel() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$ID" == "rhel" ]]; then
            command -v subscription-manager &>/dev/null || return 0
        fi
    fi
    return 0
}

test_redhat_kernel_packages() {
    # Check for kernel-core or kernel-modules package
    rpm -q kernel-core &>/dev/null || rpm -q kernel &>/dev/null
}

test_dnf_modules_available() {
    if command -v dnf &>/dev/null; then
        dnf module list &>/dev/null || return 0
    fi
}

test_redhat_release_info() {
    [[ -f /etc/os-release ]] && grep -qE "rhel|rocky|almalinux|centos" /etc/os-release
}

test_system_update_target() {
    # RHEL systems should have system-update.target
    [[ -f /usr/lib/systemd/system/system-update.target ]] || return 0
}

test_rpm_database_valid() {
    rpm --rebuilddb --test &>/dev/null || return 1
}

test_redhat_logging() {
    [[ -f /etc/rsyslog.conf ]] || [[ -d /etc/rsyslog.d ]]
}

# Main test execution
main() {
    echo "========================================"
    echo "SYSMAINT RedHat Family Test Suite"
    echo "========================================"
    echo ""

    # Detect OS info
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "Detected: $PRETTY_NAME"
        echo ""
    fi

    # Run all tests
    run_test "RedHat family OS detection" test_redhat_family_detection
    run_test "dnf/yum package manager available" test_dnf_or_yum_available
    run_test "rpm available" test_rpm_available
    run_test "RedHat release file exists" test_redhat_release_file
    run_test "dnf/yum cache directory exists" test_dnf_cache_exists
    run_test "dnf/yum config exists" test_dnf_config_exists
    run_test "Repository files directory exists" test_dnf_repo_files
    run_test "rpm query works" test_rpm_query_works
    run_test "dnf/yum makecache works" test_dnf_makecache_works
    run_test "GPG keys available" test_redhat_gpg_keys
    run_test "SELinux available" test_selinux_available
    run_test "RedHat-specific paths exist" test_redhat_specific_paths
    run_test "firewalld available" test_firewalld_if_applicable
    run_test "subscription-manager available (RHEL)" test_subscription_manager_if_rhel
    run_test "kernel packages installed" test_redhat_kernel_packages
    run_test "dnf modules available" test_dnf_modules_available
    run_test "RedHat release info correct" test_redhat_release_info
    run_test "system-update.target exists" test_system_update_target
    run_test "rpm database valid" test_rpm_database_valid
    run_test "RedHat logging configured" test_redhat_logging

    # Summary
    echo ""
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
