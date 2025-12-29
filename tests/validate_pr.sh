#!/bin/bash
#
# validate_pr.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   Run tests before PR submission
#   Validates code quality and test coverage
#
# USAGE:
#   ./tests/validate_pr.sh [OPTIONS]
#
# OPTIONS:
#   --skip-lint      Skip ShellCheck linting
#   --skip-local     Skip local Docker tests
#   --quick          Quick validation (smoke tests only)
#   --full           Full validation (all tests)
#   --help           Show this help

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Defaults
SKIP_LINT=false
SKIP_LOCAL=false
VALIDATION_TYPE="quick"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

PASS_COUNT=0
FAIL_COUNT=0

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $*"
    ((PASS_COUNT++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $*"
    ((FAIL_COUNT++))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $*"
}

show_help() {
    cat << 'EOF'
Usage: validate_pr.sh [OPTIONS]

Run validation before PR submission.

OPTIONS:
    --skip-lint      Skip ShellCheck linting
    --skip-local     Skip local Docker tests
    --quick          Quick validation (default)
    --full           Full validation (all tests)
    --help           Show this help

VALIDATION CHECKS:
    1. File existence (sysmaint, lib, tests)
    2. ShellCheck linting
    3. Script syntax validation
    4. Smoke tests (local Docker)
    5. Test result collection

EXAMPLES:
    # Quick validation
    ./validate_pr.sh

    # Full validation
    ./validate_pr.sh --full

    # Skip linting, run tests only
    ./validate_pr.sh --skip-lint

EOF
}

# Check file existence
check_file_existence() {
    log_step "Checking file existence..."

    local missing=0

    # Main files
    if [[ ! -f "$PROJECT_DIR/sysmaint" ]]; then
        log_fail "sysmaint not found"
        missing=1
    else
        log_success "sysmaint exists"
    fi

    # Lib directory
    if [[ ! -d "$PROJECT_DIR/lib" ]]; then
        log_fail "lib directory not found"
        missing=1
    else
        log_success "lib directory exists"
    fi

    # Core library files
    if [[ -f "$PROJECT_DIR/lib/core/init.sh" ]]; then
        log_success "lib/core/init.sh exists"
    else
        log_fail "lib/core/init.sh not found"
        missing=1
    fi

    # Tests directory
    if [[ ! -d "$PROJECT_DIR/tests" ]]; then
        log_fail "tests directory not found"
        missing=1
    else
        log_success "tests directory exists"
    fi

    # Test files
    local test_files=(
        "test_suite_smoke.sh"
        "test_suite_environment.sh"
        "test_suite_functions.sh"
    )

    for file in "${test_files[@]}"; do
        if [[ -f "$SCRIPT_DIR/$file" ]]; then
            log_success "$file exists"
        else
            log_fail "$file not found"
            missing=1
        fi
    done

    return $missing
}

# Run ShellCheck
run_shellcheck() {
    log_step "Running ShellCheck linting..."

    if ! command -v shellcheck &>/dev/null; then
        log_warning "ShellCheck not installed - skipping lint"
        return 0
    fi

    local errors=0

    # Check main script
    if shellcheck -S error "$PROJECT_DIR/sysmaint" 2>/dev/null; then
        log_success "sysmaint passes ShellCheck"
    else
        log_fail "sysmaint has ShellCheck errors"
        errors=1
    fi

    # Check library files
    while IFS= read -r -d '' file; do
        if shellcheck -S error "$file" 2>/dev/null; then
            log_success "$(basename "$file") passes ShellCheck"
        else
            log_fail "$(basename "$file") has ShellCheck errors"
            errors=1
        fi
    done < <(find "$PROJECT_DIR/lib" -name "*.sh" -print0 2>/dev/null)

    # Check test files
    while IFS= read -r -d '' file; do
        if shellcheck -S error "$file" 2>/dev/null; then
            log_success "$(basename "$file") passes ShellCheck"
        else
            log_warning "$(basename "$file") has ShellCheck warnings (may be intentional for tests)"
        fi
    done < <(find "$SCRIPT_DIR" -name "test_suite_*.sh" -print0 2>/dev/null)

    return $errors
}

# Validate script syntax
validate_syntax() {
    log_step "Validating script syntax..."

    local errors=0

    # Check main script syntax
    if bash -n "$PROJECT_DIR/sysmaint" 2>/dev/null; then
        log_success "sysmaint syntax valid"
    else
        log_fail "sysmaint has syntax errors"
        errors=1
    fi

    # Check library files
    while IFS= read -r -d '' file; do
        if bash -n "$file" 2>/dev/null; then
            log_success "$(basename "$file") syntax valid"
        else
            log_fail "$(basename "$file") has syntax errors"
            errors=1
        fi
    done < <(find "$PROJECT_DIR/lib" -name "*.sh" -print0 2>/dev/null)

    return $errors
}

# Run local tests
run_local_tests() {
    log_step "Running local Docker tests..."

    local profile="smoke"
    if [[ "$VALIDATION_TYPE" == "full" ]]; then
        profile="os_families"
    fi

    log_info "Test profile: $profile"

    # Run tests on Ubuntu 24.04 as representative
    if [[ -f "$SCRIPT_DIR/run_local_docker_tests.sh" ]]; then
        if bash "$SCRIPT_DIR/run_local_docker_tests.sh" \
            --os ubuntu-24 \
            --profile "$profile" 2>&1 | tee "$PROJECT_DIR/tests/validation.log"; then
            log_success "Local Docker tests passed"
        else
            log_fail "Local Docker tests failed - see tests/validation.log"
            return 1
        fi
    else
        log_warning "Local Docker test runner not found - skipping"
        return 0
    fi
}

# Generate validation report
generate_report() {
    echo ""
    echo "========================================"
    echo "PR Validation Report"
    echo "========================================"
    echo "Type:   $VALIDATION_TYPE"
    echo "Passed: $PASS_COUNT"
    echo "Failed: $FAIL_COUNT"
    echo ""

    if [[ $FAIL_COUNT -eq 0 ]]; then
        log_success "All validation checks passed!"
        echo ""
        echo "Ready to submit PR."
        return 0
    else
        log_fail "Some validation checks failed"
        echo ""
        echo "Please fix the issues before submitting PR."
        return 1
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-lint)
            SKIP_LINT=true
            shift
            ;;
        --skip-local)
            SKIP_LOCAL=true
            shift
            ;;
        --quick)
            VALIDATION_TYPE="quick"
            shift
            ;;
        --full)
            VALIDATION_TYPE="full"
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            log_fail "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Header
echo "========================================"
echo "SYSMAINT PR Validation"
echo "========================================"
echo "Type: $VALIDATION_TYPE"
echo ""

# Run validation checks
check_file_existence
echo ""

if [[ "$SKIP_LINT" == false ]]; then
    run_shellcheck
    echo ""
else
    log_info "Skipping ShellCheck linting"
fi

validate_syntax
echo ""

if [[ "$SKIP_LOCAL" == false ]]; then
    run_local_tests
    echo ""
else
    log_info "Skipping local Docker tests"
fi

# Generate report
generate_report
exit $?
