#!/bin/bash
#
# full_test.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   Complete test suite for both local Docker and GitHub Actions
#   Comprehensive testing across all scenarios
#
# USAGE:
#   ./tests/full_test.sh [OPTIONS]
#
# OPTIONS:
#   --os LIST         Comma-separated OS list (default: all)
#   --profile NAME    Test profile: smoke, full, security, performance
#   --parallel        Run tests in parallel
#   --upload          Upload results to GitHub
#   --help            Show this help

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Defaults
OS_LIST="ubuntu-24,debian-12,fedora-41"
TEST_PROFILE="full"
PARALLEL=false
UPLOAD_RESULTS=false

# Available OS
ALL_OS=("ubuntu-22" "ubuntu-24" "debian-12" "debian-13" "fedora-41"
         "rhel-9" "rhel-10" "rocky-9" "rocky-10" "almalinux-9" "centos-9"
         "arch" "opensuse")

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="$PROJECT_DIR/tests/results"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_test() {
    echo -e "${MAGENTA}[TEST]${NC} $*"
}

show_help() {
    cat << 'EOF'
Usage: full_test.sh [OPTIONS]

Run comprehensive test suite.

OPTIONS:
    --os LIST         Comma-separated OS list (default: ubuntu-24,debian-12,fedora-41)
    --profile NAME    Test profile: smoke, full, security, performance
    --parallel        Run tests in parallel
    --upload          Upload results to GitHub
    --help            Show this help

AVAILABLE OS:
    ubuntu-22, ubuntu-24, debian-12, debian-13, fedora-41
    rhel-9, rhel-10, rocky-9, rocky-10, almalinux-9, centos-9
    arch, opensuse

TEST PROFILES:
    smoke       - Fast smoke tests
    full        - All scenarios on all OS
    security    - Security-focused tests
    performance - Performance benchmarks

EXAMPLES:
    # Full test on default OS
    ./full_test.sh

    # Full test on all OS in parallel
    ./full_test.sh --os ubuntu-22,ubuntu-24,debian-12,debian-13,fedora-41,rocky-9,arch --parallel

    # Security tests on selected OS
    ./full_test.sh --profile security --os ubuntu-24,debian-12

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --os)
            OS_LIST="$2"
            shift 2
            ;;
        --profile)
            TEST_PROFILE="$2"
            shift 2
            ;;
        --parallel)
            PARALLEL=true
            shift
            ;;
        --upload)
            UPLOAD_RESULTS=true
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

# Create results directory
mkdir -p "$RESULTS_DIR"

# Header
echo "========================================"
echo "SYSMAINT Full Test Suite"
echo "========================================"
echo "OS:      $OS_LIST"
echo "Profile: $TEST_PROFILE"
echo "Parallel: $PARALLEL"
echo ""

# Start time
start_time=$(date +%s)

# Run local Docker tests
log_info "Running local Docker tests..."
if [[ "$PARALLEL" == true ]]; then
    log_test "Running in parallel..."
    bash "$SCRIPT_DIR/run_local_docker_tests.sh" \
        --os "$OS_LIST" \
        --profile "$TEST_PROFILE" \
        --parallel
else
    bash "$SCRIPT_DIR/run_local_docker_tests.sh" \
        --os "$OS_LIST" \
        --profile "$TEST_PROFILE"
fi

# Collect local results
log_info "Collecting results..."
IFS=',' read -ra OS_ARRAY <<< "$OS_LIST"
for os in "${OS_ARRAY[@]}"; do
    os_name="${os%-*}"
    os_version="${os#*-}"
    bash "$SCRIPT_DIR/collect_test_results.sh" \
        --source local-docker \
        --os "$os_name" \
        --version "$os_version" || true
done

# End time
end_time=$(date +%s)
duration=$((end_time - start_time))

# Summary
echo ""
echo "========================================"
echo "Test Complete"
echo "========================================"
echo "Duration: ${duration}s"
echo "Results:  $RESULTS_DIR"
echo ""

# Upload results if requested
if [[ "$UPLOAD_RESULTS" == true ]]; then
    log_info "Uploading results to GitHub..."
    for result_file in "$RESULTS_DIR"/local-docker-*.json; do
        if [[ -f "$result_file" ]]; then
            bash "$SCRIPT_DIR/upload_test_results.sh" --results "$result_file"
        fi
    done
fi

log_success "Full test suite complete!"
