#!/bin/bash
#
# collect_test_results.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   Collect and format test results from both local Docker and GitHub Actions
#   Outputs unified JSON format for comparison and analysis
#
# USAGE:
#   ./tests/collect_test_results.sh [OPTIONS]
#
# OPTIONS:
#   --source SOURCE    Source: local-docker or github-actions
#   --os OS           Operating system name
#   --version VERSION OS version
#   --output FILE     Output JSON file (default: auto-generated)
#   --dry-run         Show what would be collected without executing
#   --help            Show this help

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
SOURCE=""
OS_NAME=""
OS_VERSION=""
OUTPUT_FILE=""
DRY_RUN=false

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="$PROJECT_DIR/results"

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
Usage: collect_test_results.sh [OPTIONS]

Collect and format test results into unified JSON format.

OPTIONS:
    --source SOURCE    Source: local-docker, github-actions, auto-detect
    --os OS           Operating system name (ubuntu, debian, etc.)
    --version VERSION OS version (22.04, 12, etc.)
    --output FILE     Output JSON file (default: auto-generated)
    --dry-run         Show what would be collected without executing
    --help            Show this help

EXAMPLES:
    # Auto-detect and collect
    ./collect_test_results.sh

    # Collect from local Docker Ubuntu tests
    ./collect_test_results.sh --source local-docker --os ubuntu --version 24.04

    # Collect from GitHub Actions
    ./collect_test_results.sh --source github-actions --os debian --version 12

EOF
}

# Detect environment type
detect_environment() {
    if [[ -n "$GITHUB_ACTIONS" ]]; then
        echo "github-actions"
    elif [[ -f /.dockerenv ]]; then
        echo "local-docker"
    elif [[ -f /proc/1/cgroup ]] && grep -qa docker /proc/1/cgroup 2>/dev/null; then
        echo "local-docker"
    else
        echo "local-vm"
    fi
}

# Detect OS information
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

# Detect architecture
detect_architecture() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64) echo "amd64" ;;
        aarch64) echo "arm64" ;;
        *) echo "$arch" ;;
    esac
}

# Generate unique run ID
generate_run_id() {
    echo "run-$(date +%Y%m%d-%H%M%S)-$(hostname -s 2>/dev/null || echo 'unknown')-$$"
}

# Parse test suite output to JSON
parse_test_suite() {
    local suite_name="$1"
    local suite_output="$2"

    local passed=0
    local failed=0
    local total=0
    local tests_json="[]"

    # Parse test output for pass/fail counts
    while IFS= read -r line; do
        if [[ "$line" =~ Tests:\ passed:\ ([0-9]+) ]]; then
            passed="${BASH_REMATCH[1]}"
        fi
        if [[ "$line" =~ Tests:\ failed:\ ([0-9]+) ]]; then
            failed="${BASH_REMATCH[1]}"
        fi
        if [[ "$line" =~ Tests:\ run:\ ([0-9]+) ]]; then
            total="${BASH_REMATCH[1]}"
        fi
    done <<< "$suite_output"

    # Calculate total if not directly found
    if [[ $total -eq 0 ]]; then
        total=$((passed + failed))
    fi

    # Build JSON for this suite
    jq -n \
        --arg suite "$suite_name" \
        --argjson total "$total" \
        --argjson passed "$passed" \
        --argjson failed "$failed" \
        --argjson tests "$tests_json" \
        '{
            total: $total,
            passed: $passed,
            failed: $failed,
            skipped: 0,
            tests: $tests
        }'
}

# Main collection function
collect_results() {
    local source="$1"
    local os_name="$2"
    local os_version="$3"

    # Auto-detect if not specified
    if [[ -z "$source" ]]; then
        source=$(detect_environment)
        log_info "Auto-detected environment: $source"
    fi

    if [[ -z "$os_name" ]]; then
        os_name=$(detect_os_info | head -n1)
        log_info "Auto-detected OS: $os_name"
    fi

    if [[ -z "$os_version" ]]; then
        os_version=$(detect_os_info | tail -n1)
        log_info "Auto-detected version: $os_version"
    fi

    # Generate run ID
    local run_id
    run_id=$(generate_run_id)

    # Output file
    if [[ -z "$OUTPUT_FILE" ]]; then
        OUTPUT_FILE="$RESULTS_DIR/${source}-${os_name}-${os_version}-$(date +%Y%m%d-%H%M%S).json"
    fi

    # Create results directory
    mkdir -p "$RESULTS_DIR"

    # Detect architecture
    local architecture
    architecture=$(detect_architecture)

    # Get current timestamp
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Start building JSON
    local json_start
    json_start=$(jq -n \
        --arg version "1.0" \
        --arg run_id "$run_id" \
        --arg timestamp "$timestamp" \
        '{
            version: $version,
            run_id: $run_id,
            timestamp: $timestamp
        }')

    # Build environment section
    local env_json
    if [[ "$source" == "github-actions" ]]; then
        env_json=$(jq -n \
            --arg type "github-actions" \
            --arg os "$os_name" \
            --arg version "$os_version" \
            --arg arch "$architecture" \
            --arg workflow "${GITHUB_WORKFLOW:-unknown}" \
            --arg run_id "${GITHUB_RUN_ID:-unknown}" \
            --arg job "${GITHUB_JOB:-unknown}" \
            --arg repo "${GITHUB_REPOSITORY:-unknown}" \
            --arg sha "${GITHUB_SHA:-unknown}" \
            '{
                type: $type,
                os_name: $os,
                os_version: $version,
                architecture: $arch,
                hostname: (env.HOSTNAME // "github-runner"),
                github_actions: {
                    workflow: $workflow,
                    run_id: $run_id,
                    job: $job,
                    repository: $repo,
                    sha: $sha
                }
            }')
    else
        env_json=$(jq -n \
            --arg type "local-docker" \
            --arg os "$os_name" \
            --arg version "$os_version" \
            --arg arch "$architecture" \
            --arg hostname "$(hostname -s 2>/dev/null || echo 'unknown')" \
            '{
                type: $type,
                os_name: $os,
                os_version: $version,
                architecture: $arch,
                hostname: $hostname,
                container_info: {
                    platform: "docker",
                    privileged: true
                }
            }')
    fi

    # Collect test results from log files if they exist
    local results_json="{}"
    local total_passed=0
    local total_failed=0

    # Look for test result files
    for log_file in "$RESULTS_DIR"/*.log; do
        if [[ -f "$log_file" ]]; then
            local suite_name
            suite_name=$(basename "$log_file" .log)
            local suite_output
            suite_output=$(cat "$log_file" 2>/dev/null || echo "")

            if [[ -n "$suite_output" ]]; then
                local suite_result
                suite_result=$(parse_test_suite "$suite_name" "$suite_output")
                results_json=$(echo "$results_json" | jq --arg suite "$suite_name" --argjson result "$suite_result" '. + {($suite): $result}')

                # Add to totals
                local suite_passed suite_failed
                suite_passed=$(echo "$suite_result" | jq -r '.passed')
                suite_failed=$(echo "$suite_result" | jq -r '.failed')
                total_passed=$((total_passed + suite_passed))
                total_failed=$((total_failed + suite_failed))
            fi
        fi
    done

    # Calculate summary
    local total_tests=$((total_passed + total_failed))
    local pass_rate=0
    if [[ $total_tests -gt 0 ]]; then
        pass_rate=$(awk "BEGIN {printf \"%.2f\", ($total_passed / $total_tests) * 100}")
    fi

    local summary_json
    summary_json=$(jq -n \
        --argjson total "$total_tests" \
        --argjson passed "$total_passed" \
        --argjson failed "$total_failed" \
        --argjson skipped "0" \
        --argjson pass_rate "$pass_rate" \
        '{
            total: $total,
            passed: $passed,
            failed: $failed,
            skipped: $skipped,
            pass_rate: $pass_rate
        }')

    # Combine all sections
    local final_json
    final_json=$(echo "$json_start" | \
        jq --argjson env "$env_json" \
           --argjson results "$results_json" \
           --argjson summary "$summary_json" \
           --arg profile "smoke" \
        '. + {
            environment: $env,
            test_profile: $profile,
            results: $results,
            summary: $summary
        }')

    # Output
    if [[ "$DRY_RUN" == true ]]; then
        log_info "Would write results to: $OUTPUT_FILE"
        echo "$final_json" | jq '.'
    else
        echo "$final_json" | jq '.' > "$OUTPUT_FILE"
        log_success "Results written to: $OUTPUT_FILE"

        # Print summary
        echo ""
        echo "========================================"
        echo "Test Results Summary"
        echo "========================================"
        echo "Source:        $source"
        echo "OS:            $os_name $os_version"
        echo "Architecture:  $architecture"
        echo "Total tests:   $total_tests"
        echo "Passed:        $total_passed"
        echo "Failed:        $total_failed"
        echo "Pass rate:     ${pass_rate}%"
        echo ""
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --source)
            SOURCE="$2"
            shift 2
            ;;
        --os)
            OS_NAME="$2"
            shift 2
            ;;
        --version)
            OS_VERSION="$2"
            shift 2
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
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

# Run collection
collect_results "$SOURCE" "$OS_NAME" "$OS_VERSION"
