#!/usr/bin/env bash
# Cross-OS Test Runner - Execute all test suites on all supported platforms
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="$PROJECT_ROOT/test_results"
mkdir -p "$RESULTS_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# All test suites
TEST_SUITES=(
    "test_suite_smoke.sh"
    "test_suite_edge.sh"
    "test_suite_security.sh"
    "test_suite_compliance.sh"
    "test_suite_governance.sh"
    "test_suite_performance.sh"
    "test_suite_scanners.sh"
    "test_suite_combos.sh"
    "test_suite_functions.sh"
    "test_suite_os_families.sh"
    "test_suite_exit_codes.sh"
    "test_suite_environment.sh"
    "test_suite_data_types.sh"
    "test_suite_argument_matrix.sh"
    "test_suite_parallel_execution.sh"
    "test_suite_error_handling.sh"
    "test_suite_gui_mode_extended.sh"
    "test_gui_mode.sh"
    "test_json_validation.sh"
    "test_json_checksum.sh"
    "test_mock_failures.sh"
    "test_package_build.sh"
    "test_docker_detection.sh"
)

# All platforms: "image:tag:family:pm"
# Based on OFFICIAL SUPPORT list in README.md
PLATFORMS=(
    "ubuntu:24.04:debian:apt"
    "ubuntu:22.04:debian:apt"
    "debian:13:debian:apt"
    "debian:12:debian:apt"
    "fedora:39:redhat:dnf"
    "redhat/ubi10:latest:redhat:dnf"
    "rockylinux:9:redhat:dnf"
    "almalinux:9:redhat:dnf"
    "quay.io/centos/centos:stream9:redhat:dnf"
    "archlinux:latest:arch:pacman"
    "opensuse/tumbleweed:latest:suse:zypper"
)

# Platform setup commands
get_platform_setup() {
    local image="$1"
    case "$image" in
        ubuntu*|debian*)
            echo "apt-get update && apt-get install -y bash python3 ca-certificates"
            ;;
        fedora*|rocky*|almalinux*|redhat*|centos*)
            echo "dnf install -y bash python3 ca-certificates"
            ;;
        archlinux*)
            echo "pacman -Sy --noconfirm bash python3 ca-certificates"
            ;;
        opensuse*)
            echo "zypper install -y bash python3 ca-certificates"
            ;;
        *)
            echo "true"
            ;;
    esac
}

# Run test on platform
run_test_on_platform() {
    local platform="$1"
    local test_suite="$2"
    local image=$(echo "$platform" | cut -d: -f1-2)
    local safe_name="${image//\//_}_${test_suite%.sh}"
    safe_name="${safe_name//:/_}"
    local results_file="$RESULTS_DIR/${safe_name}.log"

    echo -n "  [$image] $test_suite ... "

    # Get platform-specific setup command
    local setup_cmd=$(get_platform_setup "$image")

    # Run test in Docker container
    local container_name="sysmaint_test_${safe_name}__$$"

    # Create container, setup environment, run test, capture output
    docker run --rm \
        --name "$container_name" \
        -v "$PROJECT_ROOT:/sysmaint:ro" \
        -e DRY_RUN=true \
        -e JSON_SUMMARY=true \
        "$image" \
        /bin/bash -c "$setup_cmd && cd /sysmaint && bash tests/$test_suite" \
        > "$results_file" 2>&1
    local docker_exit=$?

    # Parse actual test results from log file
    # Count PASS indicators (✅ PASS)
    local pass_count=$(grep -c "✅ PASS" "$results_file" 2>/dev/null)
    pass_count=${pass_count:-0}
    # Count FAIL indicators
    local fail_count=$(grep -c "❌ FAIL" "$results_file" 2>/dev/null)
    fail_count=${fail_count:-0}

    # Get summary line if available
    local summary_line=$(grep -E "Passed: [0-9]+.*Failed: [0-9]+" "$results_file" | tail -1)
    if [[ -n "$summary_line" ]]; then
        local total=$(echo "$summary_line" | grep -oE "Total: [0-9]+" | grep -oE "[0-9]+")
        total=${total:-$((pass_count + fail_count))}
    else
        local total=$((pass_count + fail_count))
    fi

    # Determine result based on actual test passes/fails
    if (( pass_count > 0 )) && (( fail_count == 0 )); then
        # All tests passed
        echo -e "${GREEN}✅ PASS${NC}"
        echo "    ($total tests)" >> "$RESULTS_DIR/${safe_name}.summary"
        return 0
    elif (( pass_count > 0 )); then
        # Some tests passed, some failed
        echo -e "${YELLOW}⚠️  $pass_count/$total PASS${NC}"
        echo "    ($pass_count passed, $fail_count failed)" >> "$RESULTS_DIR/${safe_name}.summary"
        return 1
    elif [[ $docker_exit -eq 0 ]] && grep -q "✅ ALL.*TESTS PASSED" "$results_file"; then
        echo -e "${GREEN}✅ PASS${NC}"
        echo "    ($total tests)" >> "$RESULTS_DIR/${safe_name}.summary"
        return 0
    else
        # No tests passed or execution error
        echo -e "${RED}❌ ERROR${NC}"
        echo "    (docker exit: $docker_exit, $pass_count/$total passed)" >> "$RESULTS_DIR/${safe_name}.summary"
        return 2
    fi
}

# Main execution
main() {
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║           CROSS-OS TEST EXECUTION                        ║"
    echo "╠════════════════════════════════════════════════════════════╣"
    echo "║  Platforms: ${#PLATFORMS[@]}                                               ║"
    echo "║  Test Suites: ${#TEST_SUITES[@]}                                             ║"
    echo "║  Total Executions: $((${#PLATFORMS[@]} * ${#TEST_SUITES[@]}))                                    ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    local total_passed=0
    local total_failed=0
    local total_errors=0

    # Check if Docker is available
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${RED}ERROR: Docker is not installed or not in PATH${NC}"
        echo "Please install Docker to run cross-OS tests."
        exit 1
    fi

    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}ERROR: Docker daemon is not running${NC}"
        echo "Please start Docker to run cross-OS tests."
        exit 1
    fi

    local start_time=$(date +%s)

    # Run tests on each platform
    for platform in "${PLATFORMS[@]}"; do
        local image=$(echo "$platform" | cut -d: -f1-2)
        echo -e "${BLUE}=== Testing on $image ===${NC}"

        for test_suite in "${TEST_SUITES[@]}"; do
            if run_test_on_platform "$platform" "$test_suite"; then
                ((total_passed++)) || true
            else
                local ret=$?
                if [[ $ret -eq 1 ]]; then
                    ((total_failed++)) || true
                else
                    ((total_errors++)) || true
                fi
            fi
        done
        echo ""
    done

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # Summary
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║           CROSS-OS TEST SUMMARY                          ║"
    echo "╠════════════════════════════════════════════════════════════╣"
    echo "║  Total Executions: $((${#PLATFORMS[@]} * ${#TEST_SUITES[@]}))                                    ║"
    echo "║  Passed:         $total_passed                                      ║"
    echo "║  Failed:         $total_failed                                      ║"
    echo "║  Errors:         $total_errors                                      ║"
    echo "║  Duration:       ${duration}s                                      ║"
    echo "╠════════════════════════════════════════════════════════════╣"
    echo "║  Results saved to: $RESULTS_DIR                  ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    # Generate per-platform summary
    echo "Generating per-platform summaries..."
    for platform in "${PLATFORMS[@]}"; do
        local image=$(echo "$platform" | cut -d: -f1-2)
        # Create safe name for summary file (replace / and : with _)
        local safe_image_name="${image//\//_}"
        safe_image_name="${safe_image_name//:/_}"
        local summary_file="$RESULTS_DIR/${safe_image_name}_summary.txt"
        {
            echo "=== $image Test Summary ==="
            echo ""
            for test_suite in "${TEST_SUITES[@]}"; do
                local safe_name="${image//\//_}_${test_suite%.sh}"
                safe_name="${safe_name//:/_}"
                if [[ -f "$RESULTS_DIR/${safe_name}.summary" ]]; then
                    echo "$test_suite: $(cat "$RESULTS_DIR/${safe_name}.summary")"
                fi
            done
        } > "$summary_file"
        echo "  Created: $summary_file"
    done

    if [[ $total_failed -eq 0 && $total_errors -eq 0 ]]; then
        echo -e "${GREEN}✅ ALL CROSS-OS TESTS PASSED${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠️  SOME CROSS-OS TESTS HAD ISSUES${NC}"
        exit 1
    fi
}

main "$@"
