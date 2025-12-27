#!/usr/bin/env bash
# GUI mode test suite for sysmaint v2.5.0
# Tests the interactive TUI interface components
# Author: Mohamed Elharery <Mohamed@Harery.com>
# Copyright (c) 2025 Mohamed Elharery

set -uo pipefail  # Removed -e to allow tests to fail without exiting

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
SYSMAINT="$REPO_ROOT/sysmaint"

# Disable pipefail for color output
set +o pipefail

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║          SYSMAINT v2.5.0 - GUI Mode Test Suite                  ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracker
declare -a FAILED_TESTS=()

# Test helper functions
test_start() {
  local test_name="$1"
  ((TESTS_RUN++))
  printf "Test %d: %s... " "$TESTS_RUN" "$test_name"
}

test_pass() {
  ((TESTS_PASSED++))
  echo -e "${GREEN}PASS${NC}"
}

test_fail() {
  local reason="$1"
  ((TESTS_FAILED++))
  FAILED_TESTS+=("Test $TESTS_RUN: $reason")
  echo -e "${RED}FAIL${NC} - $reason"
}

# Check if GUI modules are loaded
test_start "GUI module loading"
if [[ -f "$REPO_ROOT/lib/gui/interface.sh" ]]; then
  if source "$REPO_ROOT/lib/gui/interface.sh" 2>/dev/null; then
    test_pass
  else
    test_fail "Failed to source GUI module"
  fi
else
  test_fail "GUI module not found"
fi

# Test framework detection
test_start "Framework detection function"
if declare -f detect_gui_framework >/dev/null 2>&1; then
  test_pass
else
  test_fail "detect_gui_framework function not exported"
fi

# Test framework availability
test_start "Dialog or Whiptail availability"
FRAMEWORK=$(detect_gui_framework 2>/dev/null || echo "")
if [[ -n "$FRAMEWORK" ]]; then
  test_pass
  echo "  → Detected framework: $FRAMEWORK"
else
  test_fail "Neither dialog nor whiptail is installed"
  echo "  → Install with: sudo apt install dialog"
fi

# Test check_gui_available function
test_start "GUI availability check function"
if declare -f check_gui_available >/dev/null 2>&1; then
  test_pass
else
  test_fail "check_gui_available function not exported"
fi

# Test build_cli_args_from_selections function
test_start "CLI args builder function"
if declare -f build_cli_args_from_selections >/dev/null 2>&1; then
  test_pass
else
  test_fail "build_cli_args_from_selections function not exported"
fi

# Test show_gui_menu function export
test_start "GUI menu function export"
if declare -f show_gui_menu >/dev/null 2>&1; then
  test_pass
else
  test_fail "show_gui_menu function not exported"
fi

# Test show_profile_menu function export
test_start "Profile menu function export"
if declare -f show_profile_menu >/dev/null 2>&1; then
  test_pass
else
  test_fail "show_profile_menu function not exported"
fi

# Test launch_gui_mode function export
test_start "Launch GUI mode function export"
if declare -f launch_gui_mode >/dev/null 2>&1; then
  test_pass
else
  test_fail "launch_gui_mode function not exported"
fi

# Test main script integration
test_start "Main script has GUI module loading"
if grep -q "lib/gui/interface.sh" "$SYSMAINT"; then
  test_pass
else
  test_fail "Main script doesn't load GUI module"
fi

# Test --gui flag in help
test_start "--gui flag documented in usage"
if "$SYSMAINT" --help 2>&1 | grep -q "\-\-gui"; then
  test_pass
else
  test_fail "--gui flag not in help text"
fi

# Test --gui flag early detection
test_start "--gui flag early dispatch check"
if grep -q "if \[\[ \"\$arg\" == \"--gui\"" "$SYSMAINT"; then
  test_pass
else
  test_fail "--gui flag early dispatch not implemented"
fi

# Test argument builder with mock selections
test_start "Argument builder with mock selections"
declare -A mock_selections=(
  [upgrade]="on"
  [security]="off"
  [firmware]="off"
  [purge_kernels]="off"
  [orphan_purge]="on"
  [clear_tmp]="on"
  [browser_cache]="off"
  [fstrim]="off"
  [drop_caches]="off"
  [check_zombies]="on"
  [failed_services]="on"
  [json_summary]="on"
  [dry_run]="on"
  [progress_mode]="spinner"
  [color_mode]="auto"
  [keep_kernels]=""
)

RESULT=$(build_cli_args_from_selections mock_selections)
if [[ "$RESULT" == *"--upgrade"* && "$RESULT" == *"--orphan-purge"* && 
      "$RESULT" == *"--dry-run"* && "$RESULT" == *"--progress=spinner"* ]]; then
  test_pass
  echo "  → Generated: $RESULT"
else
  test_fail "Argument builder produced incorrect output: $RESULT"
fi

# Test module file permissions
test_start "GUI module file permissions"
if [[ -r "$REPO_ROOT/lib/gui/interface.sh" ]]; then
  test_pass
else
  test_fail "GUI module not readable"
fi

# Test module syntax
test_start "GUI module syntax validation"
if bash -n "$REPO_ROOT/lib/gui/interface.sh" 2>/dev/null; then
  test_pass
else
  test_fail "GUI module has syntax errors"
fi

# Test ShellCheck compliance (if available)
if command -v shellcheck >/dev/null 2>&1; then
  test_start "ShellCheck compliance (GUI module)"
  if shellcheck "$REPO_ROOT/lib/gui/interface.sh" 2>/dev/null; then
    test_pass
  else
    test_fail "ShellCheck found issues in GUI module"
  fi
fi

# Summary
echo ""
echo "════════════════════════════════════════════════════════════"
echo "GUI MODE TEST SUMMARY"
echo "════════════════════════════════════════════════════════════"
echo "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
if [[ $TESTS_FAILED -gt 0 ]]; then
  echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
  echo ""
  echo "Failed tests:"
  for failed in "${FAILED_TESTS[@]}"; do
    echo -e "  ${RED}✗${NC} $failed"
  done
else
  echo -e "Tests failed: ${GREEN}0${NC}"
fi
echo "════════════════════════════════════════════════════════════"

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo -e "${GREEN}✓ All GUI tests passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Some GUI tests failed${NC}"
  exit 1
fi
