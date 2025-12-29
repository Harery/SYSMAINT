#!/bin/bash
#
# test_single_os.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   Test a specific OS locally with Docker
#   Quick validation for single distribution testing
#
# USAGE:
#   ./tests/test_single_os.sh OS [VERSION]
#
# ARGUMENTS:
#   OS       Operating system (ubuntu, debian, fedora, rhel, rocky, almalinux, centos, arch, opensuse)
#   VERSION  OS version (optional, defaults to latest)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Default versions for each OS
declare -A DEFAULT_VERSIONS=(
    ["ubuntu"]="24.04"
    ["debian"]="12"
    ["fedora"]="41"
    ["rhel"]="9"
    ["rocky"]="9"
    ["almalinux"]="9"
    ["centos"]="stream9"
    ["arch"]="rolling"
    ["opensuse"]="tumbleweed"
)

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
Usage: test_single_os.sh OS [VERSION]

Test a specific OS locally with Docker.

ARGUMENTS:
    OS       Operating system
             Available: ubuntu, debian, fedora, rhel, rocky, almalinux,
                        centos, arch, opensuse
    VERSION  OS version (optional, uses default if not specified)

EXAMPLES:
    # Test Ubuntu with default version (24.04)
    ./test_single_os.sh ubuntu

    # Test Debian 13
    ./test_single_os.sh debian 13

    # Test Fedora 41
    ./test_single_os.sh fedora 41

    # Test Arch Linux
    ./test_single_os.sh arch

DEFAULT VERSIONS:
    ubuntu:     24.04
    debian:     12
    fedora:     41
    rhel:       9
    rocky:      9
    almalinux:  9
    centos:     stream9
    arch:       rolling
    opensuse:   tumbleweed

EOF
}

# Check Docker
check_docker() {
    if ! command -v docker &>/dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi

    if ! docker info &>/dev/null; then
        log_error "Docker daemon is not running"
        exit 1
    fi
}

# Build and run test
test_os() {
    local os="$1"
    local version="${2:-${DEFAULT_VERSIONS[$os]}}"

    # Build OS identifier
    local os_id="${os}-${version}"

    # Map OS to image
    local image
    case "$os" in
        ubuntu)
            image="sysmaint-test:ubuntu-${version}"
            ;;
        debian)
            image="sysmaint-test:debian-${version}"
            ;;
        fedora)
            image="sysmaint-test:fedora-${version}"
            ;;
        rhel)
            image="sysmaint-test:rhel-${version}"
            ;;
        rocky)
            image="sysmaint-test:rocky-${version}"
            ;;
        almalinux)
            image="sysmaint-test:almalinux-${version}"
            ;;
        centos)
            image="sysmaint-test:centos-${version}"
            ;;
        arch)
            image="sysmaint-test:arch"
            ;;
        opensuse)
            image="sysmaint-test:opensuse"
            ;;
        *)
            log_error "Unknown OS: $os"
            exit 1
            ;;
    esac

    echo "========================================"
    echo "SYSMAINT Single OS Test"
    echo "========================================"
    echo "OS:    $os"
    echo "Version: $version"
    echo "Image: $image"
    echo ""

    # Check if image exists
    if ! docker image inspect "$image" &>/dev/null; then
        log_info "Image not found, building..."
        bash "$SCRIPT_DIR/run_local_docker_tests.sh" --os "$os_id" --build || {
            log_error "Failed to build image"
            exit 1
        }
    fi

    # Run test container
    log_test "Running tests in $os $version..."

    docker run --rm \
        --name "sysmaint-test-$os" \
        --privileged \
        -e TEST_PROFILE=smoke \
        -e OS_NAME="$os" \
        -e OS_VERSION="$version" \
        "$image" \
        bash -c "cd /sysmaint/tests && bash test_suite_smoke.sh"

    local exit_code=$?

    echo ""
    if [[ $exit_code -eq 0 ]]; then
        log_success "All tests passed for $os $version"
    else
        log_error "Some tests failed for $os $version (exit code: $exit_code)"
    fi

    return $exit_code
}

# Parse arguments
if [[ $# -eq 0 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

OS_NAME="$1"
OS_VERSION="${2:-}"

# Check prerequisites
check_docker

# Run test
test_os "$OS_NAME" "$OS_VERSION"
