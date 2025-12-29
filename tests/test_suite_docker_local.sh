#!/bin/bash
#
# test_suite_docker_local.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   Docker-specific test suite for local container testing
#   Tests container isolation, privileged mode, and environment detection
#
# USAGE:
#   bash tests/test_suite_docker_local.sh
#

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

# Docker detection tests
test_docker_env_detection() {
    if [[ -f /.dockerenv ]]; then
        return 0  # Inside Docker container
    elif [[ -f /proc/1/cgroup ]] && grep -qa docker /proc/1/cgroup; then
        return 0  # Docker cgroup detected
    fi
    return 1
}

test_privileged_mode() {
    # Check if we can run commands that require privileged mode
    if systemctl --version &>/dev/null; then
        return 0
    fi
    return 1
}

test_container_isolation() {
    # Verify we're in a container environment
    [[ -f /.dockerenv ]] || return 1
    return 0
}

test_host_filesystem_access() {
    # Test that we can access host filesystem mounts
    ls -la /sysmaint > /dev/null 2>&1 || return 1
    return 0
}

test_sysmaint_accessible() {
    which sysmaint > /dev/null 2>&1 || return 1
    sysmaint --help > /dev/null 2>&1 || return 1
    return 0
}

test_test_files_accessible() {
    [[ -f /sysmaint/tests/test_suite_smoke.sh ]] || return 1
    [[ -f /sysmaint/lib/core/init.sh ]] || return 1
    return 0
}

test_sudo_available() {
    sudo -n true 2>/dev/null || return 1
    return 0
}

# Main test execution
main() {
    echo "========================================"
    echo "SYSMAINT Docker Test Suite"
    echo "========================================"
    echo ""

    # Run all tests
    run_test "Docker environment detection" test_docker_env_detection
    run_test "Privileged mode available" test_privileged_mode
    run_test "Container isolation verified" test_container_isolation
    run_test "Host filesystem accessible" test_host_filesystem_access
    run_test "SYSMAINT executable accessible" test_sysmaint_accessible
    run_test "Test files accessible" test_test_files_accessible
    run_test "Sudo available for tests" test_sudo_available

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
