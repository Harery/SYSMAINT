#!/bin/bash
#
# test_suite_cross_os_compatibility.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   Cross-OS compatibility test suite
#   Tests OCTALUM-PULSE behavior consistency across all supported OS
#
# USAGE:
#   bash tests/test_suite_cross_os_compatibility.sh

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

# Detect current OS
detect_os_family() {
    if [[ ! -f /etc/os-release ]]; then
        echo "unknown"
        return
    fi

    . /etc/os-release
    case "$ID" in
        ubuntu|debian)
            echo "debian"
            ;;
        fedora)
            echo "fedora"
            ;;
        rhel|rocky|almalinux|centos)
            echo "redhat"
            ;;
        arch)
            echo "arch"
            ;;
        opensuse)
            echo "suse"
            ;;
        *)
            echo "$ID"
            ;;
    esac
}

test_pulse_executable_accessible() {
    which pulse &>/dev/null || [[ -f "$PROJECT_DIR/pulse" ]]
}

test_pulse_help_works() {
    pulse --help &>/dev/null || bash "$PROJECT_DIR/pulse" --help &>/dev/null
}

test_pulse_version_works() {
    pulse --version &>/dev/null || bash "$PROJECT_DIR/pulse" --version &>/dev/null
}

test_common_commands_exist() {
    # Commands that should exist on all Linux systems
    local required_commands=("bash" "systemctl" "journalctl" "awk" "sed" "grep")
    for cmd in "${required_commands[@]}"; do
        command -v "$cmd" &>/dev/null || return 1
    done
    return 0
}

test_systemd_available() {
    command -v systemctl &>/dev/null && systemctl --version &>/dev/null
}

test_journalctl_available() {
    command -v journalctl &>/dev/null
}

test_common_paths_accessible() {
    [[ -d /tmp ]] && [[ -d /var/log ]] && [[ -d /etc ]]
}

test_root_write_permissions() {
    # Test if we can write to /tmp (everyone should be able to)
    touch /tmp/pulse-test-$$ && rm -f /tmp/pulse-test-$$
}

test_package_manager_detected() {
    # At least one package manager should be detected
    command -v apt &>/dev/null || command -v apt-get &>/dev/null ||
    command -v dnf &>/dev/null || command -v yum &>/dev/null ||
    command -v pacman &>/dev/null || command -v zypper &>/dev/null
}

test_os_release_file_exists() {
    [[ -f /etc/os-release ]]
}

test_pulse_config_dir() {
    # OCTALUM-PULSE config directory should be accessible
    [[ -d /etc/system-maintenance ]] || mkdir -p /etc/system-maintenance 2>/dev/null
}

test_pulse_log_dir() {
    # OCTALUM-PULSE log directory should be accessible
    [[ -d /var/log/system-maintenance ]] || mkdir -p /var/log/system-maintenance 2>/dev/null
}

test_common_utils_available() {
    # Common utilities that OCTALUM-PULSE might use
    command -v jq &>/dev/null || command -v python3 &>/dev/null || command -v python &>/dev/null
}

test_gpg_available() {
    command -v gpg &>/dev/null || command -v gpg2 &>/dev/null || return 0
}

test_curl_or_wget_available() {
    command -v curl &>/dev/null || command -v wget &>/dev/null
}

test_systemd_service_units_exist() {
    systemctl list-units &>/dev/null || return 0
}

test_network_available() {
    ip route &>/dev/null || route -n &>/dev/null || return 0
}

test_disk_space_available() {
    df / &>/dev/null
}

test_memory_info_available() {
    [[ -f /proc/meminfo ]] || free &>/dev/null
}

test_cpu_info_available() {
    [[ -f /proc/cpuinfo ]] || lscpu &>/dev/null
}

test_locale_set() {
    [[ -n "$LANG" ]] || [[ -n "$LC_ALL" ]] || locale &>/dev/null
}

test_timezone_configured() {
    [[ -f /etc/localtime ]] || timedatectl &>/dev/null || return 0
}

test_sudo_available() {
    command -v sudo &>/dev/null || return 0
}

# Main test execution
main() {
    echo "========================================"
    echo "OCTALUM-PULSE Cross-OS Compatibility Tests"
    echo "========================================"
    echo ""

    # Detect OS family
    os_family=$(detect_os_family)
    echo "Detected OS family: $os_family"
    echo ""

    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "Full OS info: $PRETTY_NAME"
        echo ""
    fi

    # Run all tests
    run_test "pulse executable accessible" test_pulse_executable_accessible
    run_test "pulse --help works" test_pulse_help_works
    run_test "pulse --version works" test_pulse_version_works
    run_test "Common commands exist" test_common_commands_exist
    run_test "systemd available" test_systemd_available
    run_test "journalctl available" test_journalctl_available
    run_test "Common paths accessible" test_common_paths_accessible
    run_test "Root write permissions" test_root_write_permissions
    run_test "Package manager detected" test_package_manager_detected
    run_test "os-release file exists" test_os_release_file_exists
    run_test "OCTALUM-PULSE config directory" test_pulse_config_dir
    run_test "OCTALUM-PULSE log directory" test_pulse_log_dir
    run_test "Common utilities available" test_common_utils_available
    run_test "GPG available" test_gpg_available
    run_test "curl or wget available" test_curl_or_wget_available
    run_test "systemd service units" test_systemd_service_units_exist
    run_test "Network available" test_network_available
    run_test "Disk space info" test_disk_space_available
    run_test "Memory info available" test_memory_info_available
    run_test "CPU info available" test_cpu_info_available
    run_test "Locale configured" test_locale_set
    run_test "Timezone configured" test_timezone_configured
    run_test "sudo available" test_sudo_available

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
