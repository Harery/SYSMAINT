#!/usr/bin/env bash
#
# SYSMAINT Container Image Publisher
# Publishes Docker images to GitHub Container Registry
#
# Usage: ./publish-packages.sh [TOKEN]
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Configuration
readonly REGISTRY="ghcr.io"
readonly OWNER="harery"
readonly IMAGE_NAME="sysmaint"
readonly VERSION="1.0.0"

# Tags to push
readonly TAGS=(
    "latest"
    "${VERSION}"
    "1"
    "ubuntu-24.04"
)

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    log_info "Docker is installed: $(docker --version | head -1)"
}

# Login to GHCR
login_ghcr() {
    local token="$1"

    if [[ -z "$token" ]]; then
        log_error "No token provided. Usage: $0 <GITHUB_TOKEN>"
        echo ""
        echo "To get a token with write:packages scope:"
        echo "  1. Visit: https://github.com/settings/tokens/new"
        echo "  2. Select scopes: write:packages, read:packages"
        echo "  3. Generate and copy the token"
        echo "  4. Run: $0 <your-token>"
        exit 1
    fi

    log_info "Logging in to ${REGISTRY}..."
    echo "$token" | docker login "${REGISTRY}" -u "${OWNER}" --password-stdin

    if [[ $? -eq 0 ]]; then
        log_info "Successfully logged in to ${REGISTRY}"
    else
        log_error "Failed to login to ${REGISTRY}"
        log_error "Make sure your token has 'write:packages' scope"
        exit 1
    fi
}

# Build the image
build_image() {
    log_info "Building container image..."

    local full_image="${REGISTRY}/${OWNER}/${IMAGE_NAME}"
    local build_args=""

    # Build with all tags
    for tag in "${TAGS[@]}"; do
        build_args="${build_args} -t ${full_image}:${tag}"
    done

    eval "docker build ${build_args} ." || {
        log_error "Docker build failed"
        exit 1
    }

    log_info "Build successful"
}

# Push all tags
push_images() {
    log_info "Pushing images to ${REGISTRY}..."

    local full_image="${REGISTRY}/${OWNER}/${IMAGE_NAME}"

    for tag in "${TAGS[@]}"; do
        log_info "Pushing: ${full_image}:${tag}"
        docker push "${full_image}:${tag}" || {
            log_error "Failed to push: ${full_image}:${tag}"
            exit 1
        }
    done

    log_info "All images pushed successfully!"
}

# Show published packages
show_packages() {
    log_info "Published packages:"
    local full_image="${REGISTRY}/${OWNER}/${IMAGE_NAME}"
    for tag in "${TAGS[@]}"; do
        echo "  - ${full_image}:${tag}"
    done
}

# Main execution
main() {
    local token="$1"

    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║     SYSMAINT Container Image Publisher v${VERSION}           ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    check_docker
    login_ghcr "$token"
    build_image
    push_images
    show_packages

    echo ""
    log_info "Package publishing complete!"
    echo ""
    echo "To pull the image:"
    echo "  docker pull ${REGISTRY}/${OWNER}/${IMAGE_NAME}:latest"
    echo ""
    echo "To run the container:"
    echo "  docker run --rm --privileged ${REGISTRY}/${OWNER}/${IMAGE_NAME}:latest"
}

# Run main function
main "$@"
