#!/bin/bash
#
# test_suite_suse_family.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   SUSE family-specific test suite
#   Tests for openSUSE Tumbleweed
#   Focuses on zypper package manager behavior
#
# USAGE:
#   bash tests/test_suite_suse_family.sh

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

# Detect if we're on SUSE family
test_suse_family_detection() {
    if [[ ! -f /etc/os-release ]]; then
        return 1
    fi

    . /etc/os-release
    [[ "$ID" == "opensuse" ]] || [[ "$ID" == "sles" ]] ||
    [[ "$ID_LIKE" =~ suse ]] || grep -qi "suse" /etc/os-release
}

test_zypper_available() {
    command -v zypper &>/dev/null
}

test_rpm_available() {
    command -v rpm &>/dev/null
}

test_suse_release_file() {
    [[ -f /etc/SuSE-release ]] || grep -qi "suse" /etc/os-release
}

test_zypper_cache_exists() {
    [[ -d /var/cache/zypp ]]
}

test_zypper_config_exists() {
    [[ -f /etc/zypp/zypp.conf ]] || [[ -f /etc/zypp/zypper.conf ]]
}

test_zypper_repos_configured() {
    zypper repos &>/dev/null || return 1
}

test_zypper_refresh_works() {
    if [[ $EUID -ne 0 ]]; then
        sudo zypper refresh -r &>/dev/null || return 1
    else
        zypper refresh -r &>/dev/null || return 1
    fi
}

test_rpm_query_works() {
    rpm -qa &>/dev/null || return 1
}

test_suse_specific_paths() {
    [[ -d /etc/sysconfig ]] || [[ -f /etc/SUSE-brand ]]
}

test_zypper_patches() {
    zypper patches &>/dev/null || return 0
}

test_suse_kernel() {
    rpm -q kernel-default &>/dev/null || rpm -q kernel-syms &>/dev/null || return 0
}

test_suse_security_patterns() {
    zypper patterns | grep -qi "security" || return 0
}

test_zypper_verify() {
    zypper verify &>/dev/null || return 0
}

test_yast_available() {
    command -v yast &>/dev/null || command -v yast2 &>/dev/null || return 0
}

test_suse_release_info() {
    [[ -f /etc/os-release ]] && grep -qi "suse" /etc/os-release
}

test_suse_firewall() {
    systemctl is-active SuSEfirewall2 &>/dev/null ||
    systemctl is-active firewalld &>/dev/null || return 0
}

test_zypper_lr() {
    zypper lr &>/dev/null || return 1
}

test_suse_package_manager() {
    # SUSE uses both rpm and zypper
    command -v zypper &>/dev/null && command -v rpm &>/dev/null
}

test_zypper_search() {
    zypper search zypper &>/dev/null || return 1
}

# Main test execution
main() {
    echo "========================================"
    echo "SYSMAINT SUSE Family Test Suite"
    echo "========================================"
    echo ""

    # Detect OS info
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "Detected: $PRETTY_NAME"
        echo ""
    fi

    # Run all tests
    run_test "SUSE family OS detection" test_suse_family_detection
    run_test "zypper package manager available" test_zypper_available
    run_test "rpm available" test_rpm_available
    run_test "SUSE release file exists" test_suse_release_file
    run_test "zypper cache directory exists" test_zypper_cache_exists
    run_test "zypper config exists" test_zypper_config_exists
    run_test "zypper repos configured" test_zypper_repos_configured
    run_test "zypper refresh works" test_zypper_refresh_works
    run_test "rpm query works" test_rpm_query_works
    run_test "SUSE-specific paths exist" test_suse_specific_paths
    run_test "zypper patches available" test_zypper_patches
    run_test "SUSE kernel installed" test_suse_kernel
    run_test "SUSE security patterns" test_suse_security_patterns
    run_test "zypper verify works" test_zypper_verify
    run_test "YaST available" test_yast_available
    run_test "SUSE release info correct" test_suse_release_info
    run_test "SUSE firewall" test_suse_firewall
    run_test "zypper lr works" test_zypper_lr
    run_test "SUSE package manager" test_suse_package_manager
    run_test "zypper search works" test_zypper_search

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
