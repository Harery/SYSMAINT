# Contributing to SYSMAINT Tests

**Version:** 1.0
**Last Updated:** 2025-12-28
**SPDX-License-Identifier:** MIT

---

## Overview

This guide explains how to contribute new tests to the SYSMAINT test infrastructure.

---

## Table of Contents

1. [Test Development Workflow](#test-development-workflow)
2. [Test Suite Template](#test-suite-template)
3. [Writing Good Tests](#writing-good-tests)
4. [Test Categories](#test-categories)
5. [Adding New Tests](#adding-new-tests)
6. [Review Process](#review-process)

---

## Test Development Workflow

```
1. Plan → 2. Write → 3. Test → 4. Document → 5. Submit
   ↓        ↓        ↓         ↓          ↓
Design  Implement  Validate  Update   PR
```

### Step 1: Plan

- Identify what needs to be tested
- Determine the test category
- Check if similar tests exist
- Choose appropriate test suite

### Step 2: Write

- Use the standard test template
- Follow naming conventions
- Add descriptive comments
- Include error handling

### Step 3: Test

- Run locally first
- Test on multiple OS
- Verify edge cases
- Check exit codes

### Step 4: Document

- Update TEST_MATRIX.md
- Add inline documentation
- Update relevant guides
- Add examples if needed

### Step 5: Submit

- Create pull request
- Request review
- Address feedback
- Merge when approved

---

## Test Suite Template

```bash
#!/bin/bash
#
# test_suite_<name>.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   Brief description of what this suite tests
#
# USAGE:
#   bash tests/test_suite_<name>.sh

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

# Logging functions
log_test() {
    echo -e "${GREEN}[TEST]${NC} $*"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $*"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $*"
}

# Test runner
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

# ============================================================================
# TEST FUNCTIONS
# ============================================================================

# Example test function
test_example_feature() {
    # Test setup
    local test_file="/tmp/test-$$"
    
    # Test execution
    # ... your test code here ...
    
    # Test cleanup
    rm -f "$test_file"
    
    # Return 0 for pass, 1 for fail
    return 0
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    echo "========================================"
    echo "SYSMAINT <Test Suite Name>"
    echo "========================================"
    echo ""

    # Run tests
    run_test "Test name" test_example_function
    # ... more tests ...

    # Summary
    echo ""
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
```

---

## Writing Good Tests

### DO ✅

1. **Be Specific**
   ```bash
   # Good
   test_apt_update_command() {
       apt-get update -qq &>/dev/null
   }
   ```

2. **Use Descriptive Names**
   ```bash
   # Good
   test_systemd_timer_file_exists()
   test_systemd_timer_syntax_valid()
   ```

3. **Clean Up Resources**
   ```bash
   # Good
   test_temp_file_cleanup() {
       local test_file="/tmp/test-$$"
       touch "$test_file"
       # ... test code ...
       rm -f "$test_file"  # Always cleanup
   }
   ```

4. **Handle Errors Gracefully**
   ```bash
   # Good
   test_optional_feature() {
       if ! command -v feature &>/dev/null; then
           return 0  # Skip if not available
       fi
       # ... test code ...
   }
   ```

5. **Test One Thing**
   ```bash
   # Good
   test_package_installation() { ... }
   test_package_removal() { ... }
   test_package_update() { ... }
   ```

### DON'T ❌

1. **Don't Be Vague**
   ```bash
   # Bad
   test_it_works() {
       # What does "it" mean?
   }
   ```

2. **Don't Use Short Names**
   ```bash
   # Bad
   test_t1() { ... }
   test_check() { ... }
   ```

3. **Don't Leave Temp Files**
   ```bash
   # Bad
   test_temp_file() {
       touch /tmp/test-file
       # No cleanup!
   }
   ```

4. **Don't Ignore Errors**
   ```bash
   # Bad
   test_something() {
       command_that_fails || true  # Always passes!
   }
   ```

5. **Don't Test Multiple Things**
   ```bash
   # Bad
   test_everything() {
       # Tests installation, removal, update all in one
   }
   ```

---

## Test Categories

### 1. Smoke Tests
**Location:** `test_suite_smoke.sh`  
**Purpose:** Basic functionality validation  
**Runtime:** < 30 seconds each

```bash
test_sysmaint_executable() {
    [[ -f "$SYSMAINT" ]]
}

test_help_command() {
    bash "$SYSMAINT" --help &>/dev/null
}
```

### 2. OS Family Tests
**Locations:** 
- `test_suite_debian_family.sh`
- `test_suite_redhat_family.sh`
- `test_suite_arch_family.sh`
- `test_suite_suse_family.sh`
- `test_suite_fedora.sh`

**Purpose:** Distribution-specific validation

```bash
test_debian_package_manager() {
    command -v apt &>/dev/null
}

test_redhat_package_manager() {
    command -v dnf &>/dev/null || command -v yum &>/dev/null
}
```

### 3. Feature Tests
**Location:** `test_suite_features.sh`  
**Purpose:** Feature-specific validation

```bash
test_package_upgrade() {
    bash "$SYSMAINT" --upgrade --dry-run &>/dev/null
}

test_system_cleanup() {
    bash "$SYSMAINT" --cleanup --dry-run &>/dev/null
}
```

### 4. Security Tests
**Location:** `test_suite_security.sh`  
**Purpose:** Security validation

```bash
test_file_permissions() {
    local perms
    perms=$(stat -c %a "$SYSMAINT" 2>/dev/null || stat -f %A "$SYSMAINT")
    [[ "$perms" =~ ^[0-7]+[575]$ ]]
}

test_root_ownership() {
    [[ "$(stat -c %U "$SYSMAINT")" == "root" ]] || return 0
}
```

### 5. Integration Tests
**Location:** `test_suite_integration.sh`  
**Purpose:** System integration validation

```bash
test_systemd_timer_exists() {
    [[ -f "/etc/systemd/system/sysmaint.timer" ]] || return 0
}

test_crontab_syntax() {
    crontab -l &>/dev/null || return 0
}
```

---

## Adding New Tests

### Step 1: Choose the Right Suite

| Test Type | Use Suite |
|-----------|-----------|
| Basic functionality | `test_suite_smoke.sh` |
| OS-specific | `test_suite_<os>_family.sh` |
| Command-line flag | `test_suite_modes.sh` |
| Feature | `test_suite_features.sh` |
| Security | `test_suite_security.sh` |
| Performance | `test_suite_performance.sh` |
| Failure case | `test_suite_edge_cases.sh` |
| Integration | `test_suite_integration.sh` |
| Docker | `test_suite_docker.sh` |
| CI/CD | `test_suite_github_actions.sh` |

### Step 2: Add Test Function

```bash
# Add to appropriate suite
test_new_feature() {
    # Setup
    local expected="value"
    local actual
    
    # Execute
    actual=$(get_value)
    
    # Verify
    [[ "$actual" == "$expected" ]]
}
```

### Step 3: Register in Main()

```bash
main() {
    echo "========================================"
    echo "SYSMAINT <Suite Name>"
    echo "========================================"
    
    # Add your test
    run_test "New feature test" test_new_feature
    
    # ... rest of tests ...
}
```

### Step 4: Update Documentation

**Add to TEST_MATRIX.md:**
```markdown
| TEST-XXX | Test name | Description |
|----------|-----------|-------------|
| TEST-XXX | New feature test | Tests new feature |
```

**Update test count in README.md:**
```markdown
| **Feature** | Specific features | 13+ | # Was 12
```

---

## Test Naming Conventions

### Function Names

```
test_<feature>_<action>()
test_<component>_<property>()
test_<scenario>_<outcome>()
```

**Examples:**
```bash
test_apt_update_command()
test_systemd_timer_file_exists()
test_network_failure_handling()
test_invalid_argument_rejection()
```

### File Names

```
test_suite_<category>.sh
```

**Examples:**
```bash
test_suite_smoke.sh
test_suite_debian_family.sh
test_suite_security.sh
test_suite_performance.sh
```

---

## Best Practices

### 1. Test Independence

Each test should work in isolation:

```bash
# Good
test_independent_test() {
    local test_file="/tmp/test-$$"
    # Setup
    # Execute
    # Cleanup
    rm -f "$test_file"
}

# Bad
test_dependent_test() {
    # Relies on state from previous test
    [[ -f "/tmp/previous-test-file" ]]
}
```

### 2. Use Return Codes

```bash
# Good
test_feature() {
    if condition; then
        return 0  # Pass
    else
        return 1  # Fail
    fi
}

# Bad
test_feature() {
    if condition; then
        echo "Pass"
    else
        echo "Fail"  # But returns 0!
    fi
}
```

### 3. Use Timeouts

```bash
# Good for potentially slow tests
test_with_timeout() {
    timeout 30 bash "$SYSMAINT" --operation &>/dev/null
}

# Bad
test_without_timeout() {
    bash "$SYSMAINT" --operation  # May hang forever
}
```

### 4. Handle Optional Features

```bash
# Good
test_optional_snap() {
    if ! command -v snap &>/dev/null; then
        return 0  # Skip gracefully
    fi
    snap list &>/dev/null
}

# Bad
test_snap() {
    snap list &>/dev/null  # Fails on non-Ubuntu
}
```

### 5. Cleanup Always

```bash
# Good
test_with_cleanup() {
    local test_file="/tmp/test-$$"
    trap "rm -f $test_file" EXIT  # Always cleanup
    
    # Test code that may fail
    may_fail_command || true
}

# Bad
test_no_cleanup() {
    local test_file="/tmp/test-$$"
    # If this fails, file never deleted
    may_fail_command
    rm -f "$test_file"
}
```

---

## Test Checklist

Before submitting, verify:

- [ ] Test follows the standard template
- [ ] Test name is descriptive
- [ ] Test handles errors gracefully
- [ ] Test cleans up resources
- [ ] Test works on multiple OS
- [ ] Test documented in TEST_MATRIX.md
- [ ] Test count updated in README.md
- [ ] Test added to appropriate profile in `run_all_tests.sh`

---

## Example: Adding a New Test

### Scenario: Testing a new feature `--backup`

**Step 1: Choose suite**
```bash
# Feature tests → test_suite_features.sh
```

**Step 2: Write test**
```bash
test_backup_command() {
    # Test backup functionality
    bash "$SYSMAINT" --backup --dry-run &>/dev/null
}

test_backup_creates_file() {
    local backup_dir="/var/backups/system-maintenance"
    
    # Run backup
    bash "$SYSMAINT" --backup --dry-run &>/dev/null
    
    # Verify directory would be created
    # (In dry-run mode, just check the command runs)
}
```

**Step 3: Register test**
```bash
main() {
    # ... existing tests ...
    
    # New tests
    run_test "Backup command" test_backup_command
    run_test "Backup creates file" test_backup_creates_file
    
    # ... rest of tests ...
}
```

**Step 4: Update documentation**

**TEST_MATRIX.md:**
```markdown
| FEAT-013 | Backup command | Backup creation |
| FEAT-014 | Backup creates file | Backup file verification |
```

**README.md:**
```markdown
| **Features** | Packages, cleanup, security, firmware, backup | 14+ | # Was 12
```

---

## Running Your Tests

### Locally
```bash
# Run specific suite
bash tests/test_suite_features.sh

# Run with verbose output
bash -x tests/test_suite_features.sh

# Run specific test
bash -c 'source tests/test_suite_features.sh && test_backup_command'
```

### In Docker
```bash
# Test on Ubuntu
bash tests/test_single_os.sh ubuntu 24.04

# Test on multiple OS
bash tests/run_local_docker_tests.sh --os ubuntu-24,debian-12
```

### Before PR
```bash
# Full validation
bash tests/validate_pr.sh
```

---

## Code Review Process

### What Reviewers Check

1. **Test Quality**
   - Does the test validate what it claims?
   - Is the test independent?
   - Are edge cases covered?

2. **Code Style**
   - Follows template?
   - Proper error handling?
   - Clear naming?

3. **Documentation**
   - TEST_MATRIX.md updated?
   - Comments clear?
   - README counts updated?

4. **Testing**
   - Runs locally?
   - Works on multiple OS?
   - Doesn't break existing tests?

### Addressing Feedback

```bash
# Make requested changes
vim tests/test_suite_features.sh

# Re-test
bash tests/test_suite_features.sh

# Update PR
git add tests/test_suite_features.sh docs/TEST_MATRIX.md
git commit -m "Address review feedback"
git push
```

---

## Advanced Topics

### Parameterized Tests

```bash
# Test multiple values
test_package_manager() {
    local managers=("apt" "dnf" "pacman" "zypper")
    local manager
    
    for manager in "${managers[@]}"; do
        if command -v "$manager" &>/dev/null; then
            echo "Testing $manager"
            # ... test code ...
        fi
    done
}
```

### Test Fixtures

```bash
# Common setup/teardown
setup_test_environment() {
    export TEST_MODE=1
    export TEST_DIR="/tmp/sysmaint-test-$$"
    mkdir -p "$TEST_DIR"
}

teardown_test_environment() {
    rm -rf "$TEST_DIR"
    unset TEST_MODE TEST_DIR
}

# Use in tests
test_with_fixture() {
    setup_test_environment
    # ... test code ...
    teardown_test_environment
}
```

### Test Helpers

```bash
# Create reusable helpers
assert_file_exists() {
    [[ -f "$1" ]]
}

assert_command_success() {
    "$@" &>/dev/null
}

assert_equals() {
    [[ "$1" == "$2" ]]
}

# Use in tests
test_file_creation() {
    local file="/tmp/test-$$"
    touch "$file"
    assert_file_exists "$file"
    rm -f "$file"
}
```

---

## Resources

- [Test Guide](TEST_GUIDE.md) - How to run tests
- [Test Cheatsheet](TEST_CHEATSHEET.md) - Quick commands
- [Test Matrix](TEST_MATRIX.md) - All tests documented
- [Test Architecture](TEST_ARCHITECTURE.md) - Design documentation
- [Troubleshooting](TEST_TROUBLESHOOTING.md) - Common issues

---

## Getting Help

### Ask Questions

- GitHub Discussions: https://github.com/Harery/SYSMAINT/discussions
- GitHub Issues: https://github.com/Harery/SYSMAINT/issues

### Example Tests

See existing test suites for examples:
- `tests/test_suite_smoke.sh` - Simple tests
- `tests/test_suite_features.sh` - Feature tests
- `tests/test_suite_security.sh` - Security tests

---

**Happy Testing! 🧪**

**Maintained by:** @Harery
**Last Updated:** 2025-12-28
**Version:** 1.0
