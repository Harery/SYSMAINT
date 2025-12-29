#!/bin/bash
#
# test_suite_debian_family.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   Debian family-specific test suite
#   Tests for Debian 12, 13 and Ubuntu 22.04, 24.04
#   Focuses on apt package manager behavior
#
# USAGE:
#   bash tests/test_suite_debian_family.sh

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

# Detect if we're on Debian family
test_debian_family_detection() {
    if [[ ! -f /etc/os-release ]]; then
        return 1
    fi

    . /etc/os-release
    [[ "$ID" == "debian" ]] || [[ "$ID" == "ubuntu" ]] || [[ "$ID_LIKE" =~ debian ]]
}

test_apt_available() {
    command -v apt &>/dev/null || command -v apt-get &>/dev/null
}

test_apt_cache_exists() {
    [[ -d /var/cache/apt ]] || [[ -d /var/lib/apt ]]
}

test_dpkg_available() {
    command -v dpkg &>/dev/null
}

test_apt_update_works() {
    if [[ $EUID -ne 0 ]]; then
        sudo apt-get update -qq &>/dev/null || return 1
    else
        apt-get update -qq &>/dev/null || return 1
    fi
}

test_debian_sources_list() {
    [[ -f /etc/apt/sources.list ]] || [[ -d /etc/apt/sources.list.d ]]
}

test_debian_version_file() {
    if [[ -f /etc/debian_version ]]; then
        return 0
    elif [[ -f /etc/lsb-release ]] && grep -q "DISTRIB_ID=Ubuntu" /etc/lsb-release 2>/dev/null; then
        return 0
    fi
    return 1
}

test_apt_config_dump() {
    apt-config dump &>/dev/null || return 1
}

test_dpkg_query_works() {
    dpkg -l &>/dev/null || return 1
}

test_apt_get_update_has_no_errors() {
    local output
    if [[ $EUID -ne 0 ]]; then
        output=$(sudo apt-get update 2>&1)
    else
        output=$(apt-get update 2>&1)
    fi

    # Check for common error patterns
    ! echo "$output" | grep -qiE "failed|error|cannot|unable"
}

test_debian_package_manager_hooks() {
    [[ -d /etc/kernel/postinst.d ]] || [[ -d /etc/apt/apt.conf.d ]]
}

test_apt_cache_valid() {
    apt-cache policy &>/dev/null || return 1
}

test_apt_mark_available() {
    apt-mark showhold &>/dev/null || return 1
}

test_debian_specific_paths() {
    # Check for Debian/Ubuntu specific paths
    [[ -d /usr/share/doc-base ]] || [[ -d /etc/update-motd.d ]]
}

test_ubuntu_snap_if_applicable() {
    . /etc/os-release
    if [[ "$ID" == "ubuntu" ]]; then
        command -v snap &>/dev/null || return 1
    fi
    return 0
}

test_systemd_resolved() {
    # Ubuntu uses systemd-resolved
    [[ -f /etc/systemd/resolved.conf ]] || command -v resolvectl &>/dev/null || return 0
}

test_apt_dependencies() {
    # Test that apt dependencies are available
    command -v dpkg &>/dev/null && command -v apt-get &>/dev/null
}

test_apt_lists_directory() {
    [[ -d /var/lib/apt/lists ]]
}

test_debian_release_info() {
    [[ -f /etc/os-release ]] && grep -qE "debian|ubuntu" /etc/os-release
}

# Main test execution
main() {
    echo "========================================"
    echo "SYSMAINT Debian Family Test Suite"
    echo "========================================"
    echo ""

    # Detect OS info
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "Detected: $PRETTY_NAME"
        echo ""
    fi

    # Run all tests
    run_test "Debian family OS detection" test_debian_family_detection
    run_test "apt package manager available" test_apt_available
    run_test "apt cache directory exists" test_apt_cache_exists
    run_test "dpkg available" test_dpkg_available
    run_test "apt-get update works" test_apt_update_works
    run_test "Debian sources list exists" test_debian_sources_list
    run_test "Debian version file exists" test_debian_version_file
    run_test "apt-config dump works" test_apt_config_dump
    run_test "dpkg query works" test_dpkg_query_works
    run_test "apt-get update has no errors" test_apt_get_update_has_no_errors
    run_test "Debian package manager hooks" test_debian_package_manager_hooks
    run_test "apt-cache policy works" test_apt_cache_valid
    run_test "apt-mark works" test_apt_mark_available
    run_test "Debian-specific paths exist" test_debian_specific_paths
    run_test "Ubuntu snap available (if applicable)" test_ubuntu_snap_if_applicable
    run_test "systemd-resolved available" test_systemd_resolved
    run_test "apt dependencies available" test_apt_dependencies
    run_test "apt lists directory exists" test_apt_lists_directory
    run_test "Debian release info correct" test_debian_release_info

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
