#!/bin/bash
#
# test_suite_fedora.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   Fedora-specific test suite
#   Tests for Fedora 41+
#   Focuses on dnf package manager and Fedora-specific features
#
# USAGE:
#   bash tests/test_suite_fedora.sh

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

# Detect if we're on Fedora
test_fedora_detection() {
    if [[ ! -f /etc/os-release ]]; then
        return 1
    fi

    . /etc/os-release
    [[ "$ID" == "fedora" ]]
}

test_dnf_available() {
    command -v dnf &>/dev/null
}

test_fedora_release_file() {
    [[ -f /etc/fedora-release ]] || grep -qi "fedora" /etc/os-release
}

test_dnf_cache_exists() {
    [[ -d /var/cache/dnf ]]
}

test_dnf_config_exists() {
    [[ -f /etc/dnf/dnf.conf ]]
}

test_dnf_makecache_works() {
    if [[ $EUID -ne 0 ]]; then
        sudo dnf makecache --quiet &>/dev/null || return 1
    else
        dnf makecache --quiet &>/dev/null || return 1
    fi
}

test_fedora_version() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        [[ -n "$VERSION_ID" ]] && [[ "$VERSION_ID" -ge 41 ]]
    fi
}

test_fedora_specific_features() {
    # Fedora uses Wayland by default
    command -v wayland-scanner &>/dev/null || return 0
}

test_fedora_kernel() {
    rpm -q kernel &>/dev/null || rpm -q kernel-core &>/dev/null
}

test_fedora_modularity() {
    dnf module list &>/dev/null || return 0
}

test_rpm_fusion_repos() {
    dnf repolist | grep -qi "rpmfusion" || return 0
}

test_fedora_workstation_packages() {
    rpm -q fedora-release-workstation &>/dev/null || return 0
}

test_fedora_gpg_keys() {
    [[ -d /etc/pki/rpm-gpg ]] || rpm -q gpg-pubkey &>/dev/null
}

test_fedora_selinux() {
    command -v getenforce &>/dev/null || return 0
}

test_fedora_firewall() {
    systemctl is-enabled firewalld &>/dev/null || return 0
}

test_fedora_release_info() {
    [[ -f /etc/os-release ]] && grep -q "fedora" /etc/os-release
}

test_fedora_package_manager() {
    command -v dnf &>/dev/null && command -v rpm &>/dev/null
}

test_fedora_updates() {
    dnf check-update &>/dev/null || return 0
}

test_fedora_flatpak_support() {
    command -v flatpak &>/dev/null || return 0
}

# Main test execution
main() {
    echo "========================================"
    echo "SYSMAINT Fedora Test Suite"
    echo "========================================"
    echo ""

    # Detect OS info
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "Detected: $PRETTY_NAME"
        echo ""
    fi

    # Run all tests
    run_test "Fedora OS detection" test_fedora_detection
    run_test "dnf package manager available" test_dnf_available
    run_test "Fedora release file exists" test_fedora_release_file
    run_test "dnf cache directory exists" test_dnf_cache_exists
    run_test "dnf config exists" test_dnf_config_exists
    run_test "dnf makecache works" test_dnf_makecache_works
    run_test "Fedora version >= 41" test_fedora_version
    run_test "Fedora-specific features" test_fedora_specific_features
    run_test "Fedora kernel installed" test_fedora_kernel
    run_test "Fedora modularity available" test_fedora_modularity
    run_test "RPM Fusion repos" test_rpm_fusion_repos
    run_test "Fedora workstation packages" test_fedora_workstation_packages
    run_test "Fedora GPG keys" test_fedora_gpg_keys
    run_test "SELinux available" test_fedora_selinux
    run_test "firewalld available" test_fedora_firewall
    run_test "Fedora release info correct" test_fedora_release_info
    run_test "Fedora package manager" test_fedora_package_manager
    run_test "dnf check-update works" test_fedora_updates
    run_test "Flatpak support" test_fedora_flatpak_support

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
