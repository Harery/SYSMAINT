#!/bin/bash
#
# run_all_tests.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   Master test runner for SYSMAINT
#   Orchestrates all test suites with configurable profiles
#
# USAGE:
#   bash tests/run_all_tests.sh [OPTIONS]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Default options
PROFILE="standard"
OS_FILTER="all"
PARALLEL=false
VERBOSE=false
DRY_RUN=false

# Stats
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0
TOTAL_TIME=0

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_header() {
    echo ""
    echo "========================================"
    echo "$*"
    echo "========================================"
    echo ""
}

# Show help
show_help() {
    cat << HELPTEXT
SYSMAINT Master Test Runner

USAGE:
    bash $0 [OPTIONS]

OPTIONS:
    --profile PROFILE     Test profile: smoke, standard, full (default: standard)
    --os-filter OS        Filter by OS family: debian, redhat, arch, suse, fedora, all
    --parallel            Run tests in parallel (where supported)
    --verbose             Verbose output
    --dry-run             Show what would be run without executing
    --help                Show this help message

PROFILES:
    smoke     - Basic functionality tests (~10 seconds)
    standard  - Core test suites (~5 minutes)
    full      - All test suites (~15 minutes)

HELPTEXT
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --profile)
                PROFILE="$2"
                shift 2
                ;;
            --os-filter)
                OS_FILTER="$2"
                shift 2
                ;;
            --parallel)
                PARALLEL=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Run a single test suite
run_suite() {
    local suite_name="$1"
    local suite_file="$2"
    local start_time
    local end_time
    local duration
    local exit_code

    ((TOTAL_SUITES++))

    if [[ ! -f "$suite_file" ]]; then
        log_warning "Suite not found: $suite_file"
        return 1
    fi

    log_info "Running: $suite_name ($suite_file)"

    if [[ "$DRY_RUN" == true ]]; then
        echo "  Would execute: bash $suite_file"
        return 0
    fi

    start_time=$(date +%s)

    if [[ "$VERBOSE" == true ]]; then
        bash "$suite_file"
    else
        bash "$suite_file" > /tmp/test-suite-${suite_name}-$$.log 2>&1
    fi

    exit_code=$?
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    TOTAL_TIME=$((TOTAL_TIME + duration))

    if [[ $exit_code -eq 0 ]]; then
        log_success "PASSED: $suite_name (${duration}s)"
        ((PASSED_SUITES++))
        return 0
    else
        log_error "FAILED: $suite_name (${duration}s)"
        ((FAILED_SUITES++))
        if [[ "$VERBOSE" == false ]]; then
            echo "  Log: /tmp/test-suite-${suite_name}-$$.log"
        fi
        return 1
    fi
}

# Run smoke tests
run_smoke_tests() {
    log_header "Running Smoke Tests"
    run_suite "smoke" "tests/test_suite_smoke.sh"
}

# Run OS family tests
run_os_family_tests() {
    log_header "Running OS Family Tests"
    
    if [[ "$OS_FILTER" == "all" ]]; then
        run_suite "debian" "tests/test_suite_debian_family.sh"
        run_suite "redhat" "tests/test_suite_redhat_family.sh"
        run_suite "arch" "tests/test_suite_arch_family.sh"
        run_suite "suse" "tests/test_suite_suse_family.sh"
        run_suite "fedora" "tests/test_suite_fedora.sh"
        run_suite "cross" "tests/test_suite_cross_os_compatibility.sh"
    else
        case "$OS_FILTER" in
            debian)
                run_suite "debian" "tests/test_suite_debian_family.sh"
                ;;
            redhat)
                run_suite "redhat" "tests/test_suite_redhat_family.sh"
                ;;
            arch)
                run_suite "arch" "tests/test_suite_arch_family.sh"
                ;;
            suse)
                run_suite "suse" "tests/test_suite_suse_family.sh"
                ;;
            fedora)
                run_suite "fedora" "tests/test_suite_fedora.sh"
                ;;
            *)
                log_warning "OS filter '$OS_FILTER' not found"
                ;;
        esac
    fi
}

# Run core tests
run_core_tests() {
    log_header "Running Core Tests"
    run_suite "modes" "tests/test_suite_modes.sh"
    run_suite "features" "tests/test_suite_features.sh"
}

# Run advanced tests
run_advanced_tests() {
    log_header "Running Advanced Tests"
    run_suite "security" "tests/test_suite_security.sh"
    run_suite "performance" "tests/test_suite_performance.sh"
    run_suite "edge" "tests/test_suite_edge_cases.sh"
    run_suite "integration" "tests/test_suite_integration.sh"
}

# Run environment tests
run_environment_tests() {
    log_header "Running Environment Tests"
    run_suite "docker" "tests/test_suite_docker.sh"
    run_suite "github" "tests/test_suite_github_actions.sh"
}

# Main execution
main() {
    parse_args "$@"

    log_header "SYSMAINT Test Runner"
    log_info "Profile: $PROFILE"
    log_info "OS Filter: $OS_FILTER"
    log_info "Parallel: $PARALLEL"
    log_info "Dry Run: $DRY_RUN"

    local start_time=$(date +%s)

    case "$PROFILE" in
        smoke)
            run_smoke_tests
            ;;
        standard)
            run_smoke_tests
            run_os_family_tests
            run_core_tests
            ;;
        full)
            run_smoke_tests
            run_os_family_tests
            run_core_tests
            run_advanced_tests
            run_environment_tests
            ;;
    esac

    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))

    # Final summary
    log_header "Test Summary"
    echo "Total Suites:   $TOTAL_SUITES"
    echo "Passed:         $PASSED_SUITES"
    echo "Failed:         $FAILED_SUITES"
    echo "Total Time:     ${TOTAL_TIME}s (~$((TOTAL_TIME / 60))m)"
    echo "Wall Time:      ${total_duration}s (~$((total_duration / 60))m)"
    echo ""

    if [[ $FAILED_SUITES -eq 0 ]]; then
        log_success "All tests passed!"
        exit 0
    else
        log_error "Some tests failed!"
        exit 1
    fi
}

main "$@"
