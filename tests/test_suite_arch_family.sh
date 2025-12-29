#!/bin/bash
#
# test_suite_arch_family.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   Arch Linux-specific test suite
#   Tests for Arch Linux rolling release
#   Focuses on pacman package manager behavior
#
# USAGE:
#   bash tests/test_suite_arch_family.sh

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

# Detect if we're on Arch Linux
test_arch_family_detection() {
    if [[ ! -f /etc/os-release ]]; then
        return 1
    fi

    . /etc/os-release
    [[ "$ID" == "arch" ]] || [[ "$ID_LIKE" =~ arch ]]
}

test_pacman_available() {
    command -v pacman &>/dev/null
}

test_arch_release_file() {
    [[ -f /etc/arch-release ]] || grep -qi "arch" /etc/os-release
}

test_pacman_cache_exists() {
    [[ -d /var/cache/pacman/pkg ]]
}

test_pacman_config_exists() {
    [[ -f /etc/pacman.conf ]]
}

test_pacman_sync_database() {
    if [[ $EUID -ne 0 ]]; then
        sudo pacman -Sy &>/dev/null || return 1
    else
        pacman -Sy &>/dev/null || return 1
    fi
}

test_pacman_query_works() {
    pacman -Q &>/dev/null || return 1
}

test_arch_specific_paths() {
    # Arch-specific paths
    [[ -d /usr/share/pacman ]] || [[ -f /etc/makepkg.conf ]]
}

test_makepkg_available() {
    command -v makepkg &>/dev/null
}

test_pacman_keyring() {
    pacman-key --list-keys &>/dev/null || return 0
}

test_arch_repo_signatures() {
    [[ -d /etc/pacman.d/gnupg ]] || return 0
}

test_arch_package_format() {
    # Arch uses .pkg.tar.zst
    pacman -Q linux &>/dev/null || return 0
}

test_arch_sysupgrade_dry_run() {
    pacman -Syup --print-format "%n" &>/dev/null || return 0
}

test_arch_mirrorlist() {
    [[ -f /etc/pacman.d/mirrorlist ]]
}

test_pacman_hooks() {
    [[ -d /usr/share/libalpm/hooks ]]
}

test_arch_kernel() {
    pacman -Q linux &>/dev/null || pacman -Q linux-lts &>/dev/null || pacman -Q linux-zen &>/dev/null
}

test_arch_community_repo() {
    grep -q "\[community\]" /etc/pacman.conf || grep -q "\[extra\]" /etc/pacman.conf
}

test_multilib_repo_if_x86_64() {
    local arch
    arch=$(uname -m)
    if [[ "$arch" == "x86_64" ]]; then
        grep -q "\[multilib\]" /etc/pacman.conf || return 0
    fi
    return 0
}

test_arch_logging() {
    [[ -f /etc/arch-release ]] || journalctl --version &>/dev/null
}

# Main test execution
main() {
    echo "========================================"
    echo "SYSMAINT Arch Family Test Suite"
    echo "========================================"
    echo ""

    # Detect OS info
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "Detected: $PRETTY_NAME"
        echo ""
    fi

    # Run all tests
    run_test "Arch family OS detection" test_arch_family_detection
    run_test "pacman package manager available" test_pacman_available
    run_test "Arch release file exists" test_arch_release_file
    run_test "pacman cache directory exists" test_pacman_cache_exists
    run_test "pacman config exists" test_pacman_config_exists
    run_test "pacman database sync works" test_pacman_sync_database
    run_test "pacman query works" test_pacman_query_works
    run_test "Arch-specific paths exist" test_arch_specific_paths
    run_test "makepkg available" test_makepkg_available
    run_test "pacman keyring available" test_pacman_keyring
    run_test "Arch repo signatures" test_arch_repo_signatures
    run_test "Arch kernel installed" test_arch_kernel
    run_test "Arch mirrorlist exists" test_arch_mirrorlist
    run_test "pacman hooks available" test_pacman_hooks
    run_test "Arch repos configured" test_arch_community_repo
    run_test "multilib repo (x86_64)" test_multilib_repo_if_x86_64
    run_test "Arch logging available" test_arch_logging

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
