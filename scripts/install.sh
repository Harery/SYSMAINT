#!/bin/bash
#
# OCTALUM-PULSE Installation Script
# https://pulse.harery.com
#
# Usage:
#   curl -sSL pulse.harery.com/install | bash
#   curl -sSL pulse.harery.com/install | bash -s -- --version v2.0.0
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

BINARY_NAME="pulse"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="${HOME}/.config/pulse"
DATA_DIR="${HOME}/.local/share/pulse"
REPO="Harery/OCTALUM-PULSE"
GITHUB_API="https://api.github.com/repos"

VERSION="${VERSION:-}"
VERBOSE="${VERBOSE:-false}"

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_banner() {
    echo -e "${BLUE}"
    echo "  ╔═══════════════════════════════════════════════════════════╗"
    echo "  ║                                                           ║"
    echo "  ║     🫀 OCTALUM-PULSE Installer                           ║"
    echo "  ║     Your Infrastructure's Heartbeat                       ║"
    echo "  ║                                                           ║"
    echo "  ╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

detect_os() {
    OS="$(uname -s)"
    case "$OS" in
        Linux*)  OS="linux" ;;
        Darwin*) OS="darwin" ;;
        *)       log_error "Unsupported OS: $OS"; exit 1 ;;
    esac
}

detect_arch() {
    ARCH="$(uname -m)"
    case "$ARCH" in
        x86_64|amd64)   ARCH="amd64" ;;
        arm64|aarch64)  ARCH="arm64" ;;
        *)              log_error "Unsupported architecture: $ARCH"; exit 1 ;;
    esac
}

get_latest_version() {
    local version
    version=$(curl -sSL "${GITHUB_API}/${REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [ -z "$version" ]; then
        version="v2.0.0"
    fi
    
    echo "$version"
}

download_binary() {
    local version="$1"
    local binary_name="${BINARY_NAME}-${version}-${OS}-${ARCH}"
    local download_url="https://github.com/${REPO}/releases/download/${version}/${binary_name}"
    
    if [ "$OS" = "windows" ]; then
        binary_name="${binary_name}.exe"
        download_url="${download_url}.exe"
    fi
    
    log_info "Downloading OCTALUM-PULSE ${version} for ${OS}/${ARCH}..."
    
    local tmp_dir
    tmp_dir=$(mktemp -d)
    local tmp_file="${tmp_dir}/${BINARY_NAME}"
    
    if ! curl -sSL --progress-bar --fail -o "$tmp_file" "$download_url"; then
        log_error "Failed to download binary from $download_url"
        rm -rf "$tmp_dir"
        exit 1
    fi
    
    chmod +x "$tmp_file"
    
    echo "$tmp_file"
}

install_binary() {
    local binary_path="$1"
    
    log_info "Installing to ${INSTALL_DIR}..."
    
    if [ -w "$INSTALL_DIR" ]; then
        mv "$binary_path" "${INSTALL_DIR}/${BINARY_NAME}"
    else
        log_info "Requires sudo to install to ${INSTALL_DIR}"
        sudo mv "$binary_path" "${INSTALL_DIR}/${BINARY_NAME}"
    fi
    
    log_success "Binary installed to ${INSTALL_DIR}/${BINARY_NAME}"
}

setup_directories() {
    log_info "Setting up directories..."
    
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$DATA_DIR"
    
    if [ ! -f "${CONFIG_DIR}/config.yaml" ]; then
        cat > "${CONFIG_DIR}/config.yaml" << 'EOF'
# OCTALUM-PULSE Configuration
# See https://pulse.harery.com/docs/configuration for details

version: 1
log_level: info

plugins:
  packages:
    enabled: true
    security_only: false
  security:
    enabled: true
    standards: [cis]
  performance:
    enabled: true

ai:
  enabled: false
  mode: local
EOF
        log_success "Created default config at ${CONFIG_DIR}/config.yaml"
    fi
}

verify_installation() {
    log_info "Verifying installation..."
    
    if ! command -v pulse &> /dev/null; then
        log_error "pulse command not found in PATH"
        exit 1
    fi
    
    local version
    version=$(pulse version --short 2>/dev/null || echo "unknown")
    
    log_success "OCTALUM-PULSE ${version} installed successfully!"
}

print_post_install() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    Installation Complete!                     ║${NC}"
    echo -e "${GREEN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC}                                                               ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  ${CYAN}Quick Start:${NC}                                                 ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}                                                               ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}    ${YELLOW}pulse doctor${NC}          Run system health check           ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}    ${YELLOW}pulse update --dry-run${NC}  Preview package updates           ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}    ${YELLOW}pulse fix --auto${NC}       Automatically fix issues          ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}                                                               ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  ${CYAN}Documentation:${NC}  https://docs.pulse.harery.com              ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  ${CYAN}Discord:${NC}        https://discord.gg/pulse                     ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}                                                               ${GREEN}║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --version|-v)
                VERSION="$2"
                shift 2
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [--version VERSION] [--verbose] [--help]"
                echo ""
                echo "Options:"
                echo "  --version, -v    Specify version to install (default: latest)"
                echo "  --verbose        Enable verbose output"
                echo "  --help, -h       Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

main() {
    print_banner
    parse_args "$@"
    
    detect_os
    detect_arch
    
    if [ -z "$VERSION" ]; then
        VERSION=$(get_latest_version)
    fi
    
    log_info "Installing OCTALUM-PULSE ${VERSION}"
    
    local binary_path
    binary_path=$(download_binary "$VERSION")
    
    install_binary "$binary_path"
    setup_directories
    verify_installation
    print_post_install
}

main "$@"
