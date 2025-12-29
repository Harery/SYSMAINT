#!/bin/bash
#
# run_dual_environment_tests.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   Orchestrate tests in both local Docker and GitHub Actions environments
#   Collects and compares results to identify discrepancies
#
# USAGE:
#   ./tests/run_dual_environment_tests.sh [OPTIONS]
#
# OPTIONS:
#   --os OS           Target OS (ubuntu, debian, fedora, etc.)
#   --version VER     OS version (22.04, 12, 41, etc.)
#   --profile NAME    Test profile (smoke, full, security, etc.)
#   --skip-local      Skip local Docker tests
#   --skip-github     Skip GitHub Actions tests
#   --compare-only    Only compare existing results
#   --upload          Upload results to GitHub
#   --help            Show this help

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Defaults
OS_NAME=""
OS_VERSION=""
TEST_PROFILE="smoke"
SKIP_LOCAL=false
SKIP_GITHUB=false
COMPARE_ONLY=false
UPLOAD_RESULTS=false

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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_test() {
    echo -e "${MAGENTA}[TEST]${NC} $*"
}

show_help() {
    cat << 'EOF'
Usage: run_dual_environment_tests.sh [OPTIONS]

Run tests in both local Docker and GitHub Actions, then compare results.

OPTIONS:
    --os OS           Target OS (ubuntu, debian, fedora, etc.)
    --version VER     OS version (22.04, 12, 41, etc.)
    --profile NAME    Test profile: smoke, full, security, performance
    --skip-local      Skip local Docker tests
    --skip-github     Skip GitHub Actions tests
    --compare-only    Only compare existing results (skip running tests)
    --upload          Upload results to GitHub after comparison
    --help            Show this help

EXAMPLES:
    # Run both local and GitHub tests for Ubuntu 24.04
    ./run_dual_environment_tests.sh --os ubuntu --version 24.04

    # Compare only existing results
    ./run_dual_environment_tests.sh --compare-only

    # Run local tests only
    ./run_dual_environment_tests.sh --os ubuntu --version 24.04 --skip-github

EOF
}

# Detect current OS
detect_os_info() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
        echo "$VERSION_ID"
    else
        echo "unknown"
        echo "unknown"
    fi
}

# Run local Docker tests
run_local_tests() {
    local os="$1"
    local version="$2"
    local profile="$3"

    log_info "Running local Docker tests..."
    log_test "OS: $os $version, Profile: $profile"

    # Build OS identifier for the test runner
    local os_id="${os}-${version}"

    # Use the existing local Docker test runner
    if [[ -f "$SCRIPT_DIR/run_local_docker_tests.sh" ]]; then
        bash "$SCRIPT_DIR/run_local_docker_tests.sh" \
            --os "$os_id" \
            --profile "$profile" \
            2>&1 | tee "$RESULTS_DIR/local-docker-${os_id}.log"
    else
        log_error "Local Docker test runner not found"
        return 1
    fi

    # Collect results
    log_info "Collecting local Docker results..."
    bash "$SCRIPT_DIR/collect_test_results.sh" \
        --source local-docker \
        --os "$os" \
        --version "$version" \
        --output "$RESULTS_DIR/local-docker-${os}-$(date +%Y%m%d-%H%M%S).json"

    log_success "Local Docker tests completed"
}

# Trigger GitHub Actions tests
run_github_tests() {
    local os="$1"
    local version="$2"
    local profile="$3"

    log_info "Triggering GitHub Actions tests..."

    # Check if gh CLI is available
    if ! command -v gh &>/dev/null; then
        log_warning "GitHub CLI not found - skipping GitHub tests"
        log_info "Install from: https://cli.github.com/"
        return 1
    fi

    # Check if authenticated
    if ! gh auth status &>/dev/null; then
        log_warning "Not authenticated with GitHub - skipping GitHub tests"
        return 1
    fi

    # Trigger workflow with inputs
    log_test "Triggering test-matrix.yml workflow..."

    gh workflow run test-matrix.yml \
        -f test_profile="$profile" \
        -f os_filter="${os}-${version}" || {
        log_error "Failed to trigger GitHub Actions workflow"
        return 1
    }

    log_success "GitHub Actions workflow triggered"
    log_info "Monitor at: $(gh repo view --json url -q '.url')/actions"

    # Wait a bit for workflow to start
    sleep 5

    # Get the run ID
    local run_id
    run_id=$(gh run list --workflow=test-matrix.yml --limit 1 --json databaseId -q '.[0].databaseId')

    if [[ -n "$run_id" ]]; then
        log_info "Run ID: $run_id"
        echo "$run_id" > "$RESULTS_DIR/github-run-id.txt"

        # Wait for completion (optional - can be very long)
        log_info "Waiting for workflow completion (may take 10-30 minutes)..."
        log_info "Press Ctrl+C to stop waiting and check status later"

        gh run watch "$run_id" --exit-status || {
            log_warning "Workflow did not complete successfully"
        }

        # Download artifacts
        log_info "Downloading test artifacts..."
        gh run download "$run_id" -D "$RESULTS_DIR/github-artifacts" || {
            log_warning "Failed to download artifacts"
        }
    fi

    log_success "GitHub Actions tests completed"
}

# Compare results
compare_results() {
    log_info "Comparing results from both environments..."

    # Find latest result files
    local latest_local
    local latest_github

    latest_local=$(find "$RESULTS_DIR" -name "*local*.json" -type f 2>/dev/null | sort -r | head -n1)
    latest_github=$(find "$RESULTS_DIR" -name "*github*.json" -type f 2>/dev/null | sort -r | head -n1)

    if [[ -z "$latest_local" ]]; then
        log_error "No local Docker results found"
        return 1
    fi

    if [[ -z "$latest_github" ]]; then
        log_warning "No GitHub Actions results found - skipping comparison"
        log_info "Local results: $latest_local"
        return 1
    fi

    log_info "Local results:  $latest_local"
    log_info "GitHub results: $latest_github"

    # Generate comparison report
    bash "$SCRIPT_DIR/report_discrepancies.sh" \
        --local "$latest_local" \
        --github "$latest_github" \
        --format all

    log_success "Comparison report generated"
}

# Upload results if requested
upload_results() {
    log_info "Uploading results to GitHub..."

    local latest_local
    latest_local=$(find "$RESULTS_DIR" -name "*local*.json" -type f 2>/dev/null | sort -r | head -n1)

    if [[ -n "$latest_local" ]]; then
        bash "$SCRIPT_DIR/upload_test_results.sh" \
            --results "$latest_local"
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --os)
            OS_NAME="$2"
            shift 2
            ;;
        --version)
            OS_VERSION="$2"
            shift 2
            ;;
        --profile)
            TEST_PROFILE="$2"
            shift 2
            ;;
        --skip-local)
            SKIP_LOCAL=true
            shift
            ;;
        --skip-github)
            SKIP_GITHUB=true
            shift
            ;;
        --compare-only)
            COMPARE_ONLY=true
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

# Auto-detect OS if not specified
if [[ -z "$OS_NAME" ]]; then
    OS_NAME=$(detect_os_info | head -n1)
    OS_VERSION=$(detect_os_info | tail -n1)
    log_info "Auto-detected OS: $OS_NAME $OS_VERSION"
fi

# Create results directory
mkdir -p "$RESULTS_DIR"

# Main execution
echo "========================================"
echo "SYSMAINT Dual Environment Test Runner"
echo "========================================"
echo "OS:       $OS_NAME $OS_VERSION"
echo "Profile:  $TEST_PROFILE"
echo ""

# Compare-only mode
if [[ "$COMPARE_ONLY" == true ]]; then
    log_info "Compare-only mode - skipping test execution"
    compare_results
    exit $?
fi

# Run local Docker tests
if [[ "$SKIP_LOCAL" == false ]]; then
    run_local_tests "$OS_NAME" "$OS_VERSION" "$TEST_PROFILE"
    echo ""
fi

# Run GitHub Actions tests
if [[ "$SKIP_GITHUB" == false ]]; then
    run_github_tests "$OS_NAME" "$OS_VERSION" "$TEST_PROFILE"
    echo ""
fi

# Compare results
compare_results

# Upload results if requested
if [[ "$UPLOAD_RESULTS" == true ]]; then
    upload_results
fi

# Summary
echo ""
echo "========================================"
echo "Dual Environment Test Complete"
echo "========================================"
echo "Results directory: $RESULTS_DIR"
echo ""
