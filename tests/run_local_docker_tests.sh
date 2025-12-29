#!/bin/bash
#
# run_local_docker_tests.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   Run SYSMAINT tests in local Docker containers for all supported OS
#   Can run single OS or multiple OS in parallel
#
# USAGE:
#   ./tests/run_local_docker_tests.sh [OPTIONS] [OS...]
#
# OPTIONS:
#   --os LIST       Comma-separated list of OS (ubuntu-24,debian-12,fedora-41,etc)
#   --profile NAME   Test profile (smoke, os_families, full, etc.)
#   --parallel      Run containers in parallel
#   --build         Rebuild images before testing
#   --dry-run       Show what would run without executing
#   --help          Show this help
#
# EXAMPLES:
#   # Run quick smoke tests on Ubuntu 24.04
#   ./tests/run_local_docker_tests.sh --os ubuntu-24
#
#   # Run tests on multiple OS in parallel
#   ./tests/run_local_docker_tests.sh --parallel --os ubuntu-24,debian-12,fedora-41
#
#   # Run full test profile on all OS
#   ./tests/run_local_docker_tests.sh --profile full --parallel
#

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
OS_LIST=""
TEST_PROFILE="smoke"
PARALLEL=false
REBUILD=false
DRY_RUN=false
BUILD_ONLY=false

# Available OS images
declare -A OS_IMAGES=(
    ["ubuntu-22"]="sysmaint-test:ubuntu-22.04"
    ["ubuntu-24"]="sysmaint-test:ubuntu-24.04"
    ["debian-12"]="sysmaint-test:debian-12"
    ["debian-13"]="sysmaint-test:debian-13"
    ["fedora-41"]="sysmaint-test:fedora-41"
    ["rhel-9"]="sysmaint-test:rhel-9"
    ["rhel-10"]="sysmaint-test:rhel-10"
    ["rocky-9"]="sysmaint-test:rocky-9"
    ["rocky-10"]="sysmaint-test:rocky-10"
    ["almalinux-9"]="sysmaint-test:almalinux-9"
    ["centos-9"]="sysmaint-test:centos-9"
    ["arch"]="sysmaint-test:arch"
    ["opensuse"]="sysmaint-test:opensuse"
)

# All OS keys
ALL_OS=("${!OS_IMAGES[@]}")

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

log_test() {
    echo -e "${MAGENTA}[TEST]${NC} $*"
}

show_help() {
    cat << 'EOF'
Usage: run_local_docker_tests.sh [OPTIONS] [OS...]

Run SYSMAINT tests in local Docker containers.

OPTIONS:
    --os LIST       Comma-separated list of OS (ubuntu-24,debian-12,fedora-41,etc)
    --profile NAME  Test profile: smoke, os_families, full, security, performance
    --parallel      Run containers in parallel
    --build         Rebuild images before testing
    --dry-run       Show what would run without executing
    --help          Show this help

AVAILABLE OS:
    ubuntu-22, ubuntu-24, debian-12, debian-13, fedora-41
    rhel-9, rhel-10, rocky-9, rocky-10, almalinux-9, centos-9
    arch, opensuse

TEST PROFILES:
    smoke       - Fast smoke tests (default)
    os_families - One from each family
    full        - All scenarios on all OS
    security    - Security-focused tests
    performance - Performance benchmarks

EXAMPLES:
    # Quick smoke test on Ubuntu 24.04
    ./run_local_docker_tests.sh --os ubuntu-24

    # Multiple OS in parallel
    ./run_local_docker_tests.sh --parallel --os ubuntu-24,debian-12,fedora-41

    # Full test profile on all OS
    ./run_local_docker_tests.sh --profile full --parallel
EOF
}

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

build_image() {
    local os="$1"
    local image="${OS_IMAGES[$os]}"

    log_info "Building $image..."

    case "$os" in
        ubuntu-22|ubuntu-24)
            local version="${os#ubuntu-}"
            docker build -f tests/docker/Dockerfile.ubuntu.test \
                --build-arg BASE_IMAGE=ubuntu:$version \
                -t "$image" .
            ;;
        debian-12|debian-13)
            local version="${os#debian-}"
            docker build -f tests/docker/Dockerfile.debian.test \
                --build-arg BASE_IMAGE=debian:$version \
                -t "$image" .
            ;;
        fedora-41)
            docker build -f tests/docker/Dockerfile.fedora.test \
                --build-arg BASE_IMAGE=fedora:41 \
                -t "$image" .
            ;;
        rhel-9|rhel-10)
            local version="${os#rhel-}"
            docker build -f tests/docker/Dockerfile.rhel.test \
                --build-arg BASE_IMAGE=registry.access.redhat.com/ubi${version} \
                --build-arg UBI_INIT=registry.access.redhat.com/ubi${version}-init \
                -t "$image" .
            ;;
        rocky-9|rocky-10)
            local version="${os#rocky}"
            docker build -f tests/docker/Dockerfile.rocky.test \
                --build-arg BASE_IMAGE=rockylinux:$version \
                -t "$image" .
            ;;
        almalinux-9)
            docker build -f tests/docker/Dockerfile.almalinux.test \
                --build-arg BASE_IMAGE=almalinux:9 \
                -t "$image" .
            ;;
        centos-9)
            docker build -f tests/docker/Dockerfile.centos.test \
                --build-arg BASE_IMAGE=quay.io/centos/centos:stream9 \
                -t "$image" .
            ;;
        arch)
            docker build -f tests/docker/Dockerfile.arch.test \
                --build-arg BASE_IMAGE=archlinux:base \
                -t "$image" .
            ;;
        opensuse)
            docker build -f tests/docker/Dockerfile.opensuse.test \
                --build-arg BASE_IMAGE=opensuse/tumbleweed \
                -t "$image" .
            ;;
        *)
            log_error "Unknown OS: $os"
            return 1
            ;;
    esac
}

run_test() {
    local os="$1"
    local image="${OS_IMAGES[$os]}"
    local container="sysmaint-test-$os"

    log_test "Running tests on $os..."

    local test_cmd="cd /sysmaint/tests && bash test_suite_smoke.sh"

    if [[ "$DRY_RUN" == true ]]; then
        echo "  Would run: docker run --rm --privileged $image $test_cmd"
        return 0
    fi

    # Check if container exists and remove it
    docker rm -f "$container" 2>/dev/null || true

    # Run test container
    docker run --rm \
        --name "$container" \
        --privileged \
        -e TEST_PROFILE="$TEST_PROFILE" \
        -e OS_NAME="${os%-*}" \
        -e OS_VERSION="${os#*-}" \
        "$image" \
        bash -c "$test_cmd"

    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_success "$os: All tests passed"
    else
        log_error "$os: Some tests failed (exit code: $exit_code)"
    fi

    return $exit_code
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
        --build)
            REBUILD=true
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
        -*)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            # Treat as OS name
            if [[ -z "$OS_LIST" ]]; then
                OS_LIST="$1"
            else
                OS_LIST="$OS_LIST,$1"
            fi
            shift
            ;;
    esac
done

# Check Docker
check_docker

# Set default OS list if none provided
if [[ -z "$OS_LIST" ]]; then
    # Default to quick smoke tests on Ubuntu 24.04
    OS_LIST="ubuntu-24"
    log_info "No OS specified, defaulting to $OS_LIST"
fi

# Parse OS list
IFS=',' read -ra TARGET_OS <<< "$OS_LIST"

# Validate OS names
for os in "${TARGET_OS[@]}"; do
    if [[ ! -v "OS_IMAGES[$os]" ]]; then
        log_error "Unknown OS: $os"
        echo "Available: ${ALL_OS[*]}"
        exit 1
    fi
done

# Show configuration
log_info "Configuration:"
echo "  OS: ${TARGET_OS[*]}"
echo "  Profile: $TEST_PROFILE"
echo "  Parallel: $PARALLEL"
echo "  Rebuild: $REBUILD"
echo "  Dry run: $DRY_RUN"
echo ""

# Build images if requested
if [[ "$REBUILD" == true ]]; then
    log_info "Building Docker images..."
    for os in "${TARGET_OS[@]}"; do
        build_image "$os" || exit 1
    done
    echo ""
fi

# Run tests
log_info "Running tests..."
exit_code=0

if [[ "$PARALLEL" == true ]]; then
    log_info "Running tests in parallel..."

    # Run tests in background
    pids=()
    for os in "${TARGET_OS[@]}"; do
        if [[ "$DRY_RUN" == true ]]; then
            run_test "$os" &
        else
            run_test "$os" > "tests/results/$os.log" 2>&1 &
        fi
        pids+=($!)
    done

    # Wait for all tests
    for i in "${!pids[@]}"; do
        os="${TARGET_OS[$i]}"
        pid="${pids[$i]}"

        if wait "$pid"; then
            log_success "$os: Passed"
        else
            log_error "$os: Failed"
            exit_code=1
        fi
    done
else
    # Run tests sequentially
    for os in "${TARGET_OS[@]}"; do
        if ! run_test "$os"; then
            exit_code=1
        fi
    done
fi

# Summary
echo ""
if [[ $exit_code -eq 0 ]]; then
    log_success "All tests passed!"
else
    log_error "Some tests failed"
fi

exit $exit_code
