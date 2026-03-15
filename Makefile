# OCTALUM-PULSE Makefile
# Build, test, and release automation

# ═══════════════════════════════════════════════════════════════════════════════
# Variables
# ═══════════════════════════════════════════════════════════════════════════════

BINARY_NAME?=pulse
VERSION?=$(shell git describe --tags --always --dirty 2>/dev/null || echo "v2.0.0-dev")
BUILD_TIME=$(shell date -u '+%Y-%m-%d_%H:%M:%S')
GIT_COMMIT=$(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
LDFLAGS=-ldflags "-X github.com/Harery/OCTALUM-PULSE/internal/version.Version=$(VERSION) \
	-X github.com/Harery/OCTALUM-PULSE/internal/version.BuildTime=$(BUILD_TIME) \
	-X github.com/Harery/OCTALUM-PULSE/internal/version.GitCommit=$(GIT_COMMIT)"

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOMOD=$(GOCMD) mod

# Directories
CMD_DIR=./cmd/pulse
AGENT_DIR=./cmd/pulse-agent
BIN_DIR=./bin
COVERAGE_DIR=./coverage

# Platform targets
PLATFORMS=darwin/amd64 darwin/arm64 linux/amd64 linux/arm64 windows/amd64

# ═══════════════════════════════════════════════════════════════════════════════
# Targets
# ═══════════════════════════════════════════════════════════════════════════════

.PHONY: all build clean test coverage lint fmt vet install release help dev

all: clean deps lint test build

# ─────────────────────────────────────────────────────────────────────────────
# Development
# ─────────────────────────────────────────────────────────────────────────────

dev: deps
	@echo "🔧 Setting up development environment..."
	@go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	@go install github.com/spf13/cobra-cli@latest
	@echo "✅ Development environment ready"

deps:
	@echo "📦 Downloading dependencies..."
	$(GOMOD) download
	$(GOMOD) verify
	@echo "✅ Dependencies ready"

tidy:
	$(GOMOD) tidy

# ─────────────────────────────────────────────────────────────────────────────
# Build
# ─────────────────────────────────────────────────────────────────────────────

build: deps
	@echo "🏗️  Building $(BINARY_NAME)..."
	@mkdir -p $(BIN_DIR)
	$(GOBUILD) $(LDFLAGS) -o $(BIN_DIR)/$(BINARY_NAME) $(CMD_DIR)
	@echo "✅ Built: $(BIN_DIR)/$(BINARY_NAME)"

build-agent: deps
	@echo "🏗️  Building pulse-agent..."
	@mkdir -p $(BIN_DIR)
	$(GOBUILD) $(LDFLAGS) -o $(BIN_DIR)/pulse-agent $(AGENT_DIR)
	@echo "✅ Built: $(BIN_DIR)/pulse-agent"

build-all: build build-agent

# Cross-platform builds
build-linux:
	GOOS=linux GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o $(BIN_DIR)/$(BINARY_NAME)-linux-amd64 $(CMD_DIR)
	GOOS=linux GOARCH=arm64 $(GOBUILD) $(LDFLAGS) -o $(BIN_DIR)/$(BINARY_NAME)-linux-arm64 $(CMD_DIR)

build-darwin:
	GOOS=darwin GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o $(BIN_DIR)/$(BINARY_NAME)-darwin-amd64 $(CMD_DIR)
	GOOS=darwin GOARCH=arm64 $(GOBUILD) $(LDFLAGS) -o $(BIN_DIR)/$(BINARY_NAME)-darwin-arm64 $(CMD_DIR)

build-windows:
	GOOS=windows GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o $(BIN_DIR)/$(BINARY_NAME)-windows-amd64.exe $(CMD_DIR)

# ─────────────────────────────────────────────────────────────────────────────
# Testing
# ─────────────────────────────────────────────────────────────────────────────

test:
	@echo "🧪 Running tests..."
	$(GOTEST) -v -race ./...

test-short:
	@echo "🧪 Running short tests..."
	$(GOTEST) -v -short -race ./...

coverage:
	@echo "📊 Generating coverage report..."
	@mkdir -p $(COVERAGE_DIR)
	$(GOTEST) -v -race -coverprofile=$(COVERAGE_DIR)/coverage.out ./...
	$(GOCMD) tool cover -html=$(COVERAGE_DIR)/coverage.out -o $(COVERAGE_DIR)/coverage.html
	@echo "✅ Coverage report: $(COVERAGE_DIR)/coverage.html"

coverage-report: coverage
	$(GOCMD) tool cover -func=$(COVERAGE_DIR)/coverage.out

benchmark:
	@echo "⏱️  Running benchmarks..."
	$(GOTEST) -bench=. -benchmem ./...

# ─────────────────────────────────────────────────────────────────────────────
# Code Quality
# ─────────────────────────────────────────────────────────────────────────────

fmt:
	@echo "✨ Formatting code..."
	@gofmt -s -w .
	@goimports -w . 2>/dev/null || true

vet:
	@echo "🔍 Running go vet..."
	$(GOCMD) vet ./...

lint:
	@echo "🔍 Running linter..."
	@golangci-lint run --timeout 5m ./...

lint-fix:
	@golangci-lint run --fix --timeout 5m ./...

# ─────────────────────────────────────────────────────────────────────────────
# Installation
# ─────────────────────────────────────────────────────────────────────────────

install: build
	@echo "📦 Installing $(BINARY_NAME)..."
	@cp $(BIN_DIR)/$(BINARY_NAME) /usr/local/bin/
	@echo "✅ Installed to /usr/local/bin/$(BINARY_NAME)"

uninstall:
	@echo "🗑️  Uninstalling $(BINARY_NAME)..."
	@rm -f /usr/local/bin/$(BINARY_NAME)
	@rm -rf ~/.config/pulse
	@echo "✅ Uninstalled"

# ─────────────────────────────────────────────────────────────────────────────
# Docker
# ─────────────────────────────────────────────────────────────────────────────

docker-build:
	@echo "🐳 Building Docker image..."
	docker build -t ghcr.io/harery/octalum-pulse:$(VERSION) -f deployments/docker/Dockerfile .

docker-push:
	@echo "🐳 Pushing Docker image..."
	docker push ghcr.io/harery/octalum-pulse:$(VERSION)

docker-all: docker-build docker-push

# ─────────────────────────────────────────────────────────────────────────────
# Release
# ─────────────────────────────────────────────────────────────────────────────

release: clean deps test build-linux build-darwin build-windows
	@echo "🚀 Release artifacts ready in $(BIN_DIR)/"
	@ls -la $(BIN_DIR)/

# ─────────────────────────────────────────────────────────────────────────────
# Clean
# ─────────────────────────────────────────────────────────────────────────────

clean:
	@echo "🧹 Cleaning..."
	@rm -rf $(BIN_DIR)
	@rm -rf $(COVERAGE_DIR)
	$(GOCLEAN)

# ─────────────────────────────────────────────────────────────────────────────
# Documentation
# ─────────────────────────────────────────────────────────────────────────────

docs:
	@echo "📚 Generating documentation..."
	@./scripts/generate-docs.sh

docs-serve:
	@echo "📚 Serving documentation..."
	@cd docs && python3 -m http.server 8000

# ─────────────────────────────────────────────────────────────────────────────
# Utility
# ─────────────────────────────────────────────────────────────────────────────

version:
	@echo "$(VERSION)"

info:
	@echo "Version:    $(VERSION)"
	@echo "Commit:     $(GIT_COMMIT)"
	@echo "Build Time: $(BUILD_TIME)"
	@echo "Go Version: $$(go version)"

# ─────────────────────────────────────────────────────────────────────────────
# Help
# ─────────────────────────────────────────────────────────────────────────────

help:
	@echo "OCTALUM-PULSE Build System"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Development:"
	@echo "  dev          Set up development environment"
	@echo "  deps         Download dependencies"
	@echo "  tidy         Tidy go modules"
	@echo ""
	@echo "Build:"
	@echo "  build        Build the binary"
	@echo "  build-agent  Build the agent binary"
	@echo "  build-all    Build all binaries"
	@echo "  build-linux  Build for Linux (amd64, arm64)"
	@echo "  build-darwin Build for macOS (amd64, arm64)"
	@echo "  build-windows Build for Windows (amd64)"
	@echo ""
	@echo "Testing:"
	@echo "  test         Run all tests"
	@echo "  test-short   Run short tests"
	@echo "  coverage     Generate coverage report"
	@echo "  benchmark    Run benchmarks"
	@echo ""
	@echo "Quality:"
	@echo "  fmt          Format code"
	@echo "  vet          Run go vet"
	@echo "  lint         Run golangci-lint"
	@echo "  lint-fix     Run linter with auto-fix"
	@echo ""
	@echo "Docker:"
	@echo "  docker-build Build Docker image"
	@echo "  docker-push  Push Docker image"
	@echo ""
	@echo "Release:"
	@echo "  release      Build release artifacts"
	@echo "  install      Install binary locally"
	@echo "  uninstall    Uninstall binary"
	@echo ""
	@echo "Utility:"
	@echo "  clean        Clean build artifacts"
	@echo "  version      Print version"
	@echo "  info         Print build info"
	@echo "  help         Show this help"
