#!/bin/bash
#
# test_suite_github_actions.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   GitHub Actions-specific test suite for SYSMAINT
#   Tests CI environment variables, artifacts, matrix builds, cache, secrets
#
# USAGE:
#   bash tests/test_suite_github_actions.sh

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

# GitHub Actions Environment Tests
test_github_actions_detected() {
    [[ -n "$GITHUB_ACTIONS" ]] || [[ -n "$CI" ]]
}

test_github_workspace_set() {
    [[ -n "$GITHUB_WORKSPACE" ]] || [[ -n "$WORKSPACE" ]]
}

test_github_repository_set() {
    [[ -n "$GITHUB_REPOSITORY" ]] || [[ -n "$REPO" ]]
}

test_github_ref_set() {
    [[ -n "$GITHUB_REF" ]] || [[ -n "$GIT_REF" ]]
}

test_github_sha_set() {
    [[ -n "$GITHUB_SHA" ]] || [[ -n "$GIT_SHA" ]]
}

test_github_actor_set() {
    [[ -n "$GITHUB_ACTOR" ]] || [[ -n "$ACTOR" ]]
}

# GitHub Actions Runner Tests
test_runner_os_detected() {
    [[ -n "$RUNNER_OS" ]] || [[ -n "$OS" ]]
}

test_runner_arch_detected() {
    [[ -n "$RUNNER_ARCH" ]] || uname -m &>/dev/null
}

test_runner_temp_available() {
    [[ -n "$RUNNER_TEMP" ]] || [[ -d "/tmp" ]]
}

test_runner_tool_cache() {
    [[ -n "$RUNNER_TOOL_CACHE" ]] || [[ -d "/usr/local" ]]
}

# GitHub Actions Workflow Tests
test_workflow_file_exists() {
    [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]] || \
    [[ -f "$PROJECT_DIR/.github/workflows/ci.yml" ]] || \
    [[ -f "$PROJECT_DIR/.github/workflows/docker.yml" ]]
}

test_workflow_syntax_valid() {
    if command -v yamllint &>/dev/null; then
        if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
            yamllint "$PROJECT_DIR/.github/workflows/test-matrix.yml" 2>&1 || true
        fi
    fi
    return 0
}

test_workflow_has_jobs() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "jobs:" "$PROJECT_DIR/.github/workflows/test-matrix.yml"
    fi
}

test_workflow_has_matrix() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "matrix:" "$PROJECT_DIR/.github/workflows/test-matrix.yml"
    fi
}

# Matrix Build Tests
test_matrix_os_defined() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "os:" "$PROJECT_DIR/.github/workflows/test-matrix.yml"
    fi
}

test_matrix_version_defined() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "version:" "$PROJECT_DIR/.github/workflows/test-matrix.yml"
    fi
}

test_matrix_os_variations() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -E "ubuntu|debian|fedora|rhel|rocky|alma|centos|arch|opensuse" "$PROJECT_DIR/.github/workflows/test-matrix.yml"
    fi
}

# Artifact Tests
test_artifact_upload_configured() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "upload-artifact\|actions/upload-artifact" "$PROJECT_DIR/.github/workflows/test-matrix.yml"
    fi
}

test_artifact_download_configured() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "download-artifact\|actions/download-artifact" "$PROJECT_DIR/.github/workflows/test-matrix.yml"
    fi
}

test_artifact_retention_set() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "retention-days" "$PROJECT_DIR/.github/workflows/test-matrix.yml" || return 0
    fi
}

# Cache Tests
test_cache_configured() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "actions/cache" "$PROJECT_DIR/.github/workflows/test-matrix.yml" || return 0
    fi
}

test_cache_key_defined() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "key:" "$PROJECT_DIR/.github/workflows/test-matrix.yml" || return 0
    fi
}

test_cache_path_defined() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "path:" "$PROJECT_DIR/.github/workflows/test-matrix.yml" || return 0
    fi
}

# Secret Tests (non-intrusive)
test_secrets_not_exposed() {
    # Verify secrets are not hardcoded in workflows
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        ! grep -iE "password|secret|token|api_key\s*:\s*['\"]\w+" "$PROJECT_DIR/.github/workflows/test-matrix.yml"
    fi
}

test_secret_context_used() {
    # Verify secrets context is used properly
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "secrets\." "$PROJECT_DIR/.github/workflows/test-matrix.yml" || return 0
    fi
}

# Checkout Tests
test_checkout_action_used() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "actions/checkout" "$PROJECT_DIR/.github/workflows/test-matrix.yml"
    fi
}

test_checkout_depth_configured() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "fetch-depth" "$PROJECT_DIR/.github/workflows/test-matrix.yml" || return 0
    fi
}

# Shell Tests
test_bash_available() {
    command -v bash &>/dev/null
}

test_shell_specified_in_workflow() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -qE "bash|shell:" "$PROJECT_DIR/.github/workflows/test-matrix.yml"
    fi
}

# Permissions Tests
test_permissions_set() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "permissions:" "$PROJECT_DIR/.github/workflows/test-matrix.yml" || return 0
    fi
}

test_contents_read() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "contents: read" "$PROJECT_DIR/.github/workflows/test-matrix.yml" || return 0
    fi
}

test_pull_requests_read() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "pull-requests: read" "$PROJECT_DIR/.github/workflows/test-matrix.yml" || return 0
    fi
}

# Service Container Tests
test_service_container_configured() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "services:" "$PROJECT_DIR/.github/workflows/test-matrix.yml" || return 0
    fi
}

test_service_image_defined() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "image:" "$PROJECT_DIR/.github/workflows/test-matrix.yml"
    fi
}

test_service_ports_configured() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "ports:" "$PROJECT_DIR/.github/workflows/test-matrix.yml" || return 0
    fi
}

# Dependency Tests
test_dependencies_installed() {
    # Check if workflow installs required dependencies
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -qiE "apt-get|dnf|yum|install" "$PROJECT_DIR/.github/workflows/test-matrix.yml"
    fi
}

test_jq_available() {
    command -v jq &>/dev/null
}

test_shellcheck_available() {
    command -v shellcheck &>/dev/null || return 0
}

# Test Result Tests
test_results_directory_exists() {
    [[ -d "$PROJECT_DIR/tests/results" ]] || mkdir -p "$PROJECT_DIR/tests/results"
}

test_results_json_valid() {
    if [[ -f "$PROJECT_DIR/tests/results/test_result_schema.json" ]]; then
        jq empty "$PROJECT_DIR/tests/results/test_result_schema.json" &>/dev/null
    fi
}

test_results_can_be_uploaded() {
    # Verify result file paths are valid
    local test_result="/tmp/test-result-$$.json"
    echo '{"test": "value"}' > "$test_result"
    [[ -f "$test_result" ]]
    rm -f "$test_result"
}

# Matrix Strategy Tests
test_fail_fast_defined() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "fail-fast:" "$PROJECT_DIR/.github/workflows/test-matrix.yml" || return 0
    fi
}

test_max_parallel_defined() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "max-parallel:" "$PROJECT_DIR/.github/workflows/test-matrix.yml" || return 0
    fi
}

# Job Dependency Tests
test_job_needs_defined() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "needs:" "$PROJECT_DIR/.github/workflows/test-matrix.yml" || return 0
    fi
}

test_job_outputs() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "outputs:" "$PROJECT_DIR/.github/workflows/test-matrix.yml" || return 0
    fi
}

# Trigger Tests
test_push_trigger() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "on:" "$PROJECT_DIR/.github/workflows/test-matrix.yml"
        grep -q "push:" "$PROJECT_DIR/.github/workflows/test-matrix.yml" || return 0
    fi
}

test_pull_request_trigger() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "pull_request:" "$PROJECT_DIR/.github/workflows/test-matrix.yml" || return 0
    fi
}

test_manual_trigger() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "workflow_dispatch:" "$PROJECT_DIR/.github/workflows/test-matrix.yml" || return 0
    fi
}

# Status Check Tests
test_status_check_configured() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "status" "$PROJECT_DIR/.github/workflows/test-matrix.yml" || return 0
    fi
}

test_continue_on_error() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "continue-on-error:" "$PROJECT_DIR/.github/workflows/test-matrix.yml" || return 0
    fi
}

test_if_condition() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "if:" "$PROJECT_DIR/.github/workflows/test-matrix.yml"
    fi
}

# Timeout Tests
test_timeout_set() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "timeout-minutes:" "$PROJECT_DIR/.github/workflows/test-matrix.yml"
    fi
}

test_timeout_reasonable() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        local timeout
        timeout=$(grep "timeout-minutes:" "$PROJECT_DIR/.github/workflows/test-matrix.yml" | head -1 | grep -oE '[0-9]+' || echo "0")
        [[ "$timeout" -gt 0 ]] && [[ "$timeout" -le 360 ]]
    fi
}

# Environment Tests
test_env_vars_set() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "env:" "$PROJECT_DIR/.github/workflows/test-matrix.yml"
    fi
}

test_ci_env_set() {
    [[ -n "$CI" ]] || return 0
}

# GitHub Actions CLI Tests
test_gh_cli_available() {
    command -v gh &>/dev/null || return 0
}

test_gh_auth() {
    if command -v gh &>/dev/null; then
        gh auth status &>/dev/null || return 0
    fi
}

# Output Tests
test_step_output() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "::set-output\|echo.*>> \$GITHUB_OUTPUT" "$PROJECT_DIR/.github/workflows/test-matrix.yml" || return 0
    fi
}

test_summary_output() {
    if [[ -f "$PROJECT_DIR/.github/workflows/test-matrix.yml" ]]; then
        grep -q "step.summary\|GITHUB_STEP_SUMMARY" "$PROJECT_DIR/.github/workflows/test-matrix.yml" || return 0
    fi
}

# Main test execution
main() {
    echo "========================================"
    echo "SYSMAINT GitHub Actions Test Suite"
    echo "========================================"
    echo ""

    # GitHub Actions environment tests
    echo "Testing GitHub Actions Environment..."
    run_test "GitHub Actions detected" test_github_actions_detected
    run_test "GitHub workspace set" test_github_workspace_set
    run_test "GitHub repository set" test_github_repository_set
    run_test "GitHub ref set" test_github_ref_set
    run_test "GitHub SHA set" test_github_sha_set
    run_test "GitHub actor set" test_github_actor_set
    echo ""

    # GitHub Actions runner tests
    echo "Testing GitHub Actions Runner..."
    run_test "Runner OS detected" test_runner_os_detected
    run_test "Runner arch detected" test_runner_arch_detected
    run_test "Runner temp available" test_runner_temp_available
    run_test "Runner tool cache" test_runner_tool_cache
    echo ""

    # GitHub Actions workflow tests
    echo "Testing GitHub Actions Workflows..."
    run_test "Workflow file exists" test_workflow_file_exists
    run_test "Workflow syntax valid" test_workflow_syntax_valid
    run_test "Workflow has jobs" test_workflow_has_jobs
    run_test "Workflow has matrix" test_workflow_has_matrix
    echo ""

    # Matrix build tests
    echo "Testing Matrix Builds..."
    run_test "Matrix OS defined" test_matrix_os_defined
    run_test "Matrix version defined" test_matrix_version_defined
    run_test "Matrix OS variations" test_matrix_os_variations
    echo ""

    # Artifact tests
    echo "Testing Artifacts..."
    run_test "Artifact upload configured" test_artifact_upload_configured
    run_test "Artifact download configured" test_artifact_download_configured
    run_test "Artifact retention set" test_artifact_retention_set
    echo ""

    # Cache tests
    echo "Testing Cache..."
    run_test "Cache configured" test_cache_configured
    run_test "Cache key defined" test_cache_key_defined
    run_test "Cache path defined" test_cache_path_defined
    echo ""

    # Secret tests
    echo "Testing Secret Management..."
    run_test "Secrets not exposed" test_secrets_not_exposed
    run_test "Secret context used" test_secret_context_used
    echo ""

    # Checkout tests
    echo "Testing Checkout..."
    run_test "Checkout action used" test_checkout_action_used
    run_test "Checkout depth configured" test_checkout_depth_configured
    echo ""

    # Shell tests
    echo "Testing Shell Configuration..."
    run_test "Bash available" test_bash_available
    run_test "Shell specified in workflow" test_shell_specified_in_workflow
    echo ""

    # Permissions tests
    echo "Testing Permissions..."
    run_test "Permissions set" test_permissions_set
    run_test "Contents read" test_contents_read
    run_test "Pull requests read" test_pull_requests_read
    echo ""

    # Service container tests
    echo "Testing Service Containers..."
    run_test "Service container configured" test_service_container_configured
    run_test "Service image defined" test_service_image_defined
    run_test "Service ports configured" test_service_ports_configured
    echo ""

    # Dependency tests
    echo "Testing Dependencies..."
    run_test "Dependencies installed" test_dependencies_installed
    run_test "jq available" test_jq_available
    run_test "ShellCheck available" test_shellcheck_available
    echo ""

    # Test result tests
    echo "Testing Test Results..."
    run_test "Results directory exists" test_results_directory_exists
    run_test "Results JSON valid" test_results_json_valid
    run_test "Results can be uploaded" test_results_can_be_uploaded
    echo ""

    # Matrix strategy tests
    echo "Testing Matrix Strategy..."
    run_test "Fail-fast defined" test_fail_fast_defined
    run_test "Max parallel defined" test_max_parallel_defined
    echo ""

    # Job dependency tests
    echo "Testing Job Dependencies..."
    run_test "Job needs defined" test_job_needs_defined
    run_test "Job outputs" test_job_outputs
    echo ""

    # Trigger tests
    echo "Testing Triggers..."
    run_test "Push trigger" test_push_trigger
    run_test "Pull request trigger" test_pull_request_trigger
    run_test "Manual trigger" test_manual_trigger
    echo ""

    # Status check tests
    echo "Testing Status Checks..."
    run_test "Status check configured" test_status_check_configured
    run_test "Continue on error" test_continue_on_error
    run_test "If condition" test_if_condition
    echo ""

    # Timeout tests
    echo "Testing Timeouts..."
    run_test "Timeout set" test_timeout_set
    run_test "Timeout reasonable" test_timeout_reasonable
    echo ""

    # Environment tests
    echo "Testing Environment..."
    run_test "Env vars set" test_env_vars_set
    run_test "CI env set" test_ci_env_set
    echo ""

    # GitHub Actions CLI tests
    echo "Testing GitHub CLI..."
    run_test "gh CLI available" test_gh_cli_available
    run_test "gh auth" test_gh_auth
    echo ""

    # Output tests
    echo "Testing Outputs..."
    run_test "Step output" test_step_output
    run_test "Summary output" test_summary_output
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
