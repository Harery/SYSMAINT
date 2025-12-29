#!/bin/bash
#
# quick_test.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   Fast smoke tests for both local Docker and GitHub Actions environments
#   Quick validation before committing or PR submission
#
# USAGE:
#   ./tests/quick_test.sh [OPTIONS]
#
# OPTIONS:
#   --os OS           Target OS (default: auto-detect)
#   --local-only      Run local Docker tests only
#   --github-only     Trigger GitHub Actions only
#   --skip-compare    Skip result comparison
#   --help            Show this help

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Defaults
OS_NAME=""
OS_VERSION=""
OS_ID=""
LOCAL_ONLY=false
GITHUB_ONLY=false
SKIP_COMPARE=false

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

show_help() {
    cat << 'EOF'
Usage: quick_test.sh [OPTIONS]

Quick smoke tests for fast validation.

OPTIONS:
    --os OS_ID        Target OS (default: auto-detect)
                     Formats: "ubuntu" (auto version) or "ubuntu-24.04"
    --local-only      Run local Docker tests only
    --github-only     Trigger GitHub Actions only
    --skip-compare    Skip result comparison
    --help            Show this help

EXAMPLES:
    # Quick test on current system
    ./quick_test.sh

    # Test specific OS locally (auto-detect version)
    ./quick_test.sh --os ubuntu --local-only

    # Test specific OS version
    ./quick_test.sh --os ubuntu-24.04 --local-only

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

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --os)
            OS_INPUT="$2"
            # Check if input contains hyphen (e.g., "ubuntu-24.04")
            if [[ "$OS_INPUT" =~ ^[a-z]+- ]]; then
                OS_ID="$OS_INPUT"
                # Parse OS name and version from ID
                OS_NAME="${OS_INPUT%%-*}"
                OS_VERSION="${OS_INPUT#*-}"
            else
                # Simple OS name provided, will auto-detect version
                OS_NAME="$OS_INPUT"
            fi
            shift 2
            ;;
        --local-only)
            LOCAL_ONLY=true
            shift
            ;;
        --github-only)
            GITHUB_ONLY=true
            shift
            ;;
        --skip-compare)
            SKIP_COMPARE=true
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
elif [[ -z "$OS_VERSION" ]]; then
    # OS name specified but version not - detect version
    OS_VERSION=$(detect_os_info | tail -n1)
fi

# Build OS identifier if not already set
if [[ -z "$OS_ID" ]]; then
    OS_ID="${OS_NAME}-${OS_VERSION}"
fi

echo "========================================"
echo "SYSMAINT Quick Test"
echo "========================================"
echo "OS: $OS_ID"
echo ""

# Run local tests (unless github-only)
if [[ "$GITHUB_ONLY" == false ]]; then
    log_info "Running local smoke tests..."

    # Check if we're already in Docker
    if [[ -f /.dockerenv ]] || grep -qa docker /proc/1/cgroup 2>/dev/null; then
        log_info "Running inside Docker - executing smoke tests directly"
        bash "$SCRIPT_DIR/test_suite_smoke.sh"
    else
        log_info "Running local Docker tests..."
        if [[ -f "$SCRIPT_DIR/run_local_docker_tests.sh" ]]; then
            bash "$SCRIPT_DIR/run_local_docker_tests.sh" --os "$OS_ID"
        else
            log_error "Local Docker test runner not found"
            exit 1
        fi
    fi

    echo ""
fi

# Trigger GitHub tests (unless local-only)
if [[ "$LOCAL_ONLY" == false ]]; then
    if command -v gh &>/dev/null && gh auth status &>/dev/null; then
        log_info "Triggering GitHub Actions smoke tests..."
        gh workflow run test-matrix.yml -f test_profile=smoke -f os_filter="$OS_ID"
        log_success "GitHub Actions triggered"
    else
        log_warning "GitHub CLI not available - skipping CI tests"
    fi
fi

echo ""
log_success "Quick test complete!"
