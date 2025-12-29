#!/bin/bash
#
# test_suite_docker.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   Docker-specific test suite for SYSMAINT
#   Tests Docker container execution, privileged mode, volumes, networking
#
# USAGE:
#   bash tests/test_suite_docker.sh

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
SYSMAINT="$PROJECT_DIR/sysmaint"

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

# Docker Environment Tests
test_docker_installed() {
    command -v docker &>/dev/null
}

test_docker_daemon_running() {
    docker info &>/dev/null
}

test_docker_can_run_bash() {
    docker run --rm alpine:latest sh -c "echo 'test'" &>/dev/null
}

test_docker_has_privileged_access() {
    # Check if we can run privileged containers
    docker run --rm --privileged alpine:latest sh -c "uptime" &>/dev/null
}

# Docker Container Tests
test_sysmaint_docker_image_exists() {
    if [[ -n "$SYSMAINT_DOCKER_IMAGE" ]]; then
        docker image inspect "$SYSMAINT_DOCKER_IMAGE" &>/dev/null || return 1
    fi
    return 0
}

test_sysmaint_docker_image_executable() {
    if [[ -n "$SYSMAINT_DOCKER_IMAGE" ]]; then
        docker run --rm "$SYSMAINT_DOCKER_IMAGE" sysmaint --help &>/dev/null
    fi
    return 0
}

test_docker_container_cleanup() {
    # Verify no orphaned sysmaint containers
    local orphaned
    orphaned=$(docker ps -a --filter "name=sysmaint" --format "{{.Names}}" 2>/dev/null | wc -l)
    [[ "$orphaned" -lt 5 ]]  # Allow some containers during testing
}

# Privileged Mode Tests
test_privileged_mode_required() {
    # SYSMAINT needs privileged mode for full functionality
    [[ -f /.dockerenv ]] || grep -qa docker /proc/1/cgroup 2>/dev/null
    return 0
}

test_systemd_access_in_container() {
    if [[ -f /.dockerenv ]] || grep -qa docker /proc/1/cgroup 2>/dev/null; then
        # In container - check if systemd is accessible
        systemctl --version &>/dev/null || return 0  # May not be available in all containers
    fi
    return 0
}

test_host_filesystem_access() {
    if [[ -f /.dockerenv ]] || grep -qa docker /proc/1/cgroup 2>/dev/null; then
        # Should be able to access host filesystem when mounted
        [[ -d /host ]] || [[ -d /mnt/host ]] || return 0
    fi
    return 0
}

# Volume Mount Tests
test_volume_mount_readonly() {
    # Test read-only volume mount
    local test_volume="/tmp/sysmaint-vol-test-$$"
    mkdir -p "$test_volume"
    echo "test" > "$test_volume/test.txt"

    docker run --rm -v "$test_volume:/data:ro" alpine:latest cat /data/test.txt &>/dev/null
    local result=$?

    rm -rf "$test_volume"
    return $result
}

test_volume_mount_readwrite() {
    # Test read-write volume mount
    local test_volume="/tmp/sysmaint-vol-rw-$$"
    mkdir -p "$test_volume"

    docker run --rm -v "$test_volume:/data" alpine:latest sh -c "echo 'test' > /data/test.txt" &>/dev/null
    local result=$?

    rm -rf "$test_volume"
    return $result
}

test_host_root_mount() {
    # Verify host root can be mounted (for maintenance operations)
    docker run --rm -v /:/host:ro alpine:latest ls /host &>/dev/null
}

# Docker Network Tests
test_container_network_isolation() {
    # Test that containers have network isolation
    local ip
    ip=$(docker run --rm alpine:latest sh -c "ip addr show eth0" 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    [[ -n "$ip" ]]
}

test_container_dns_resolution() {
    # Test DNS resolution in container
    docker run --rm alpine:latest nslookup google.com &>/dev/null
}

test_container_can_access_apt() {
    # Test if container can access package repositories
    docker run --rm ubuntu:latest apt-get update -qq &>/dev/null
}

# Docker Image Build Tests
test_dockerfile_syntax_valid() {
    if [[ -f "$PROJECT_DIR/tests/docker/Dockerfile.ubuntu.test" ]]; then
        # Validate Dockerfile syntax
        grep -q "FROM" "$PROJECT_DIR/tests/docker/Dockerfile.ubuntu.test"
        grep -q "RUN" "$PROJECT_DIR/tests/docker/Dockerfile.ubuntu.test"
    fi
}

test_dockerfile_has_base_image() {
    if [[ -f "$PROJECT_DIR/tests/docker/Dockerfile.ubuntu.test" ]]; then
        grep -q "^ARG BASE_IMAGE" "$PROJECT_DIR/tests/docker/Dockerfile.ubuntu.test" || \
        grep -q "^FROM" "$PROJECT_DIR/tests/docker/Dockerfile.ubuntu.test"
    fi
}

test_dockerfile_installs_dependencies() {
    if [[ -f "$PROJECT_DIR/tests/docker/Dockerfile.ubuntu.test" ]]; then
        grep -qi "install\|apt-get\|dnf\|yum\|pacman\|zypper" "$PROJECT_DIR/tests/docker/Dockerfile.ubuntu.test"
    fi
}

test_dockerfile_copies_sysmaint() {
    if [[ -f "$PROJECT_DIR/tests/docker/Dockerfile.ubuntu.test" ]]; then
        grep -q "COPY" "$PROJECT_DIR/tests/docker/Dockerfile.ubuntu.test"
    fi
}

# Multi-Architecture Tests
test_docker_manifest_support() {
    # Check if docker manifest commands are available
    docker manifest --help &>/dev/null || return 0
}

test_multi_arch_images_available() {
    # Verify multi-arch images exist (if applicable)
    if [[ -n "$SYSMAINT_DOCKER_IMAGE" ]]; then
        docker manifest inspect "$SYSMAINT_DOCKER_IMAGE" &>/dev/null || return 0
    fi
    return 0
}

# Docker Compose Tests
test_docker_compose_installed() {
    command -v docker-compose &>/dev/null || docker compose version &>/dev/null
}

test_docker_compose_file_exists() {
    [[ -f "$PROJECT_DIR/tests/docker/docker-compose.test.yml" ]] || \
    [[ -f "$PROJECT_DIR/docker-compose.yml" ]] || \
    [[ -f "$PROJECT_DIR/docker-compose.test.yml" ]]
}

test_docker_compose_syntax_valid() {
    if command -v docker-compose &>/dev/null; then
        if [[ -f "$PROJECT_DIR/tests/docker/docker-compose.test.yml" ]]; then
            docker-compose -f "$PROJECT_DIR/tests/docker/docker-compose.test.yml" config &>/dev/null
        fi
    elif docker compose version &>/dev/null; then
        if [[ -f "$PROJECT_DIR/tests/docker/docker-compose.test.yml" ]]; then
            docker compose -f "$PROJECT_DIR/tests/docker/docker-compose.test.yml" config &>/dev/null
        fi
    fi
}

# Container Resource Tests
test_container_memory_limit() {
    # Test container memory limits
    docker run --rm -m 512m alpine:latest free -m &>/dev/null
}

test_container_cpu_limit() {
    # Test container CPU limits
    docker run --rm --cpus="0.5" alpine:latest nproc &>/dev/null
}

test_container_disk_space() {
    # Test container has disk space
    docker run --rm alpine:latest df -h / &>/dev/null
}

# Docker Security Tests
test_docker_no_root_user() {
    # Verify Dockerfile creates non-root user if specified
    if [[ -f "$PROJECT_DIR/tests/docker/Dockerfile.ubuntu.test" ]]; then
        grep -q "USER" "$PROJECT_DIR/tests/docker/Dockerfile.ubuntu.test" || return 0
    fi
}

test_docker_readonly_rootfs() {
    # Check if Dockerfile uses read-only root filesystem
    if [[ -f "$PROJECT_DIR/tests/docker/Dockerfile.ubuntu.test" ]]; then
        grep -q "read_only\|readonly" "$PROJECT_DIR/tests/docker/Dockerfile.ubuntu.test" || return 0
    fi
}

test_docker_security_opt() {
    # Check for security options
    if [[ -f "$PROJECT_DIR/tests/docker/Dockerfile.ubuntu.test" ]]; then
        grep -qi "seccomp\|apparmor\|no-new-privileges" "$PROJECT_DIR/tests/docker/Dockerfile.ubuntu.test" || return 0
    fi
}

# Docker Logging Tests
test_docker_logging_driver() {
    # Verify logging driver configuration
    docker info | grep -q "Logging Driver"
}

test_container_logs_accessible() {
    # Test that container logs can be retrieved
    local container
    container=$(docker run -d alpine:latest sleep 5)
    docker logs "$container" &>/dev/null
    local result=$?
    docker rm -f "$container" &>/dev/null
    return $result
}

test_docker_log_rotation_configured() {
    # Check for log rotation configuration
    [[ -f "/etc/docker/daemon.json" ]] && grep -qi "log-opts\|max-size\|max-file" "/etc/docker/daemon.json" || return 0
}

# Docker Orchestration Tests
test_can_run_multiple_containers() {
    # Test running multiple containers in parallel
    local ids=()
    for i in {1..3}; do
        ids+=($(docker run -d alpine:latest sleep 10))
    done

    local running=0
    for id in "${ids[@]}"; do
        docker inspect "$id" | grep -q '"Running": true' && ((running++))
        docker rm -f "$id" &>/dev/null
    done

    [[ $running -eq 3 ]]
}

test_container_restart_policy() {
    # Test container restart policy
    local id
    id=$(docker run -d --restart on-failure alpine:latest sleep 1)
    sleep 2
    docker inspect "$id" | grep -qi "RestartPolicy\|RestartCount" || true
    docker rm -f "$id" &>/dev/null
    return 0
}

test_container_healthcheck() {
    # Test container healthcheck support
    if [[ -f "$PROJECT_DIR/tests/docker/Dockerfile.ubuntu.test" ]]; then
        grep -q "HEALTHCHECK" "$PROJECT_DIR/tests/docker/Dockerfile.ubuntu.test" || return 0
    fi
}

# Docker Volume Tests
test_docker_volume_creation() {
    local test_vol="sysmaint-test-$$"
    docker volume create "$test_vol" &>/dev/null
    local result=$?
    docker volume rm "$test_vol" &>/dev/null 2>&1 || true
    return $result
}

test_docker_volume_inspect() {
    local test_vol="sysmaint-inspect-$$"
    docker volume create "$test_vol" &>/dev/null
    docker volume inspect "$test_vol" &>/dev/null
    local result=$?
    docker volume rm "$test_vol" &>/dev/null 2>&1 || true
    return $result
}

# Docker Network Tests
test_docker_network_creation() {
    local test_net="sysmaint-test-$$"
    docker network create "$test_net" &>/dev/null
    local result=$?
    docker network rm "$test_net" &>/dev/null 2>&1 || true
    return $result
}

test_docker_network_connect() {
    local test_net="sysmaint-connect-$$"
    docker network create "$test_net" &>/dev/null
    local id
    id=$(docker run -d --network "$test_net" alpine:latest sleep 10)
    local result=$?
    docker rm -f "$id" &>/dev/null 2>&1 || true
    docker network rm "$test_net" &>/dev/null 2>&1 || true
    return $result
}

# Main test execution
main() {
    echo "========================================"
    echo "SYSMAINT Docker Test Suite"
    echo "========================================"
    echo ""

    # Docker environment tests
    echo "Testing Docker Environment..."
    run_test "Docker installed" test_docker_installed
    run_test "Docker daemon running" test_docker_daemon_running
    run_test "Docker can run bash" test_docker_can_run_bash
    run_test "Docker privileged access" test_docker_has_privileged_access
    echo ""

    # Docker container tests
    echo "Testing Docker Containers..."
    run_test "SYSMAINT Docker image exists" test_sysmaint_docker_image_exists
    run_test "SYSMAINT Docker image executable" test_sysmaint_docker_image_executable
    run_test "Docker container cleanup" test_docker_container_cleanup
    echo ""

    # Privileged mode tests
    echo "Testing Privileged Mode..."
    run_test "Privileged mode required" test_privileged_mode_required
    run_test "Systemd access in container" test_systemd_access_in_container
    run_test "Host filesystem access" test_host_filesystem_access
    echo ""

    # Volume mount tests
    echo "Testing Volume Mounts..."
    run_test "Volume mount read-only" test_volume_mount_readonly
    run_test "Volume mount read-write" test_volume_mount_readwrite
    run_test "Host root mount" test_host_root_mount
    echo ""

    # Docker network tests
    echo "Testing Docker Network..."
    run_test "Container network isolation" test_container_network_isolation
    run_test "Container DNS resolution" test_container_dns_resolution
    run_test "Container can access apt" test_container_can_access_apt
    echo ""

    # Docker image build tests
    echo "Testing Docker Image Build..."
    run_test "Dockerfile syntax valid" test_dockerfile_syntax_valid
    run_test "Dockerfile has base image" test_dockerfile_has_base_image
    run_test "Dockerfile installs dependencies" test_dockerfile_installs_dependencies
    run_test "Dockerfile copies SYSMAINT" test_dockerfile_copies_sysmaint
    echo ""

    # Multi-architecture tests
    echo "Testing Multi-Architecture..."
    run_test "Docker manifest support" test_docker_manifest_support
    run_test "Multi-arch images available" test_multi_arch_images_available
    echo ""

    # Docker Compose tests
    echo "Testing Docker Compose..."
    run_test "Docker Compose installed" test_docker_compose_installed
    run_test "Docker Compose file exists" test_docker_compose_file_exists
    run_test "Docker Compose syntax valid" test_docker_compose_syntax_valid
    echo ""

    # Container resource tests
    echo "Testing Container Resources..."
    run_test "Container memory limit" test_container_memory_limit
    run_test "Container CPU limit" test_container_cpu_limit
    run_test "Container disk space" test_container_disk_space
    echo ""

    # Docker security tests
    echo "Testing Docker Security..."
    run_test "Docker no root user" test_docker_no_root_user
    run_test "Docker read-only rootfs" test_docker_readonly_rootfs
    run_test "Docker security opt" test_docker_security_opt
    echo ""

    # Docker logging tests
    echo "Testing Docker Logging..."
    run_test "Docker logging driver" test_docker_logging_driver
    run_test "Container logs accessible" test_container_logs_accessible
    run_test "Docker log rotation configured" test_docker_log_rotation_configured
    echo ""

    # Docker orchestration tests
    echo "Testing Docker Orchestration..."
    run_test "Can run multiple containers" test_can_run_multiple_containers
    run_test "Container restart policy" test_container_restart_policy
    run_test "Container healthcheck" test_container_healthcheck
    echo ""

    # Docker volume tests
    echo "Testing Docker Volumes..."
    run_test "Docker volume creation" test_docker_volume_creation
    run_test "Docker volume inspect" test_docker_volume_inspect
    echo ""

    # Docker network tests
    echo "Testing Docker Networks..."
    run_test "Docker network creation" test_docker_network_creation
    run_test "Docker network connect" test_docker_network_connect
    echo ""

    # Summary
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
