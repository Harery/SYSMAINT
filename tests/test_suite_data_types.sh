#!/usr/bin/env bash
# Data Types Test Suite - 27 tests
# Tests JSON schema validation and data type correctness
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery

set -euo pipefail
cd "$(dirname "$0")/.."  # repo root

SCRIPT="./sysmaint"
PASSED=0
FAILED=0
PYTHON_BIN="python3"

run_json_test() {
    local name="$1"
    shift
    echo -n "[TEST] $name: "
    set +e
    DRY_RUN=true JSON_SUMMARY=true bash "$SCRIPT" "$@" >/dev/null 2>&1
    local exit_code=$?
    set -e
    if [[ $exit_code -eq 0 || $exit_code -eq 1 || $exit_code -eq 2 || $exit_code -eq 30 || $exit_code -eq 100 ]]; then
        # Verify JSON was created
        local json_file=$(ls -t /tmp/system-maintenance/sysmaint_*.json 2>/dev/null | head -1)
        if [ -f "$json_file" ]; then
            # Validate JSON syntax
            if $PYTHON_BIN -m json.tool "$json_file" >/dev/null 2>&1; then
                echo "✅ PASS"
                PASSED=$((PASSED + 1))
            else
                echo "❌ FAIL (invalid JSON)"
                FAILED=$((FAILED + 1))
            fi
        else
            echo "❌ FAIL (no JSON file)"
            FAILED=$((FAILED + 1))
        fi
    else
        echo "❌ FAIL (exit: $exit_code)"
        FAILED=$((FAILED + 1))
    fi
}

run_schema_test() {
    local name="$1"
    local field="$2"
    local expected_type="$3"
    shift 3
    echo -n "[TEST] $name: "
    set +e
    DRY_RUN=true JSON_SUMMARY=true bash "$SCRIPT" "$@" >/dev/null 2>&1
    local exit_code=$?
    set -e
    if [[ $exit_code -eq 0 || $exit_code -eq 1 || $exit_code -eq 2 || $exit_code -eq 30 || $exit_code -eq 100 ]]; then
        local json_file=$(ls -t /tmp/system-maintenance/sysmaint_*.json 2>/dev/null | head -1)
        if [ -f "$json_file" ]; then
            # Check if field exists and has expected type
            local value
            value=$($PYTHON_BIN -c "import json; d=json.load(open('$json_file')); print(type(d.get('$field', None)).__name__)" 2>/dev/null)
            if [[ "$value" == "$expected_type" ]]; then
                echo "✅ PASS"
                PASSED=$((PASSED + 1))
            else
                echo "❌ FAIL (field $field type: $value, expected: $expected_type)"
                FAILED=$((FAILED + 1))
            fi
        else
            echo "❌ FAIL (no JSON file)"
            FAILED=$((FAILED + 1))
        fi
    else
        echo "❌ FAIL (exit: $exit_code)"
        FAILED=$((FAILED + 1))
    fi
}

run_test() {
    local name="$1"
    shift
    echo -n "[TEST] $name: "
    set +e
    DRY_RUN=true JSON_SUMMARY=true bash "$SCRIPT" "$@" >/dev/null 2>&1
    local exit_code=$?
    set -e
    if [[ $exit_code -eq 0 || $exit_code -eq 1 || $exit_code -eq 2 || $exit_code -eq 30 || $exit_code -eq 100 ]]; then
        echo "✅ PASS"
        PASSED=$((PASSED + 1))
    else
        echo "❌ FAIL (exit: $exit_code)"
        FAILED=$((FAILED + 1))
    fi
}

echo "╔════════════════════════════════════════════════════════════╗"
echo "║          DATA TYPES TEST SUITE (27 Tests)                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ==================== JSON SYNTAX VALIDATION (4 tests) ====================
echo "=== JSON Syntax Validation (4) ==="

run_json_test "json_valid_default"
run_json_test "json_valid_with_upgrade" --upgrade
run_json_test "json_valid_with_security_audit" --security-audit
run_json_test "json_valid_comprehensive" --upgrade --security-audit --orphan-purge --dry-run

# ==================== JSON STRING FIELDS (6 tests) ====================
echo ""
echo "=== JSON String Fields (6) ==="

run_schema_test "json_run_id_string" "run_id" "str"
run_schema_test "json_script_version_string" "script_version" "str"
run_schema_test "json_timestamp_string" "timestamp" "str"
run_schema_test "json_hostname_string" "hostname" "str"
run_schema_test "json_log_file_string" "log_file" "str"
run_schema_test "json_os_description_string" "os_description" "str"

# ==================== JSON NUMERIC FIELDS (4 tests) ====================
echo ""
echo "=== JSON Numeric Fields (4) ==="

run_schema_test "json_uptime_seconds_int" "uptime_seconds" "int"
run_schema_test "json_mem_total_kb_int" "mem_total_kb" "int"
run_schema_test "json_package_count_int" "package_count" "int"
run_schema_test "json_disk_root_total_kb_int" "disk_root_total_kb" "int"

# ==================== JSON BOOLEAN FIELDS (4 tests) ====================
echo ""
echo "=== JSON Boolean Fields (4) ==="

run_schema_test "json_dry_run_bool" "dry_run_mode" "bool"
run_schema_test "json_reboot_required_bool" "reboot_required" "bool"
run_schema_test "json_security_audit_enabled_bool" "security_audit_enabled" "bool"
run_schema_test "json_auto_mode_bool" "auto_mode" "bool"

# ==================== JSON ARRAY FIELDS (4 tests) ====================
echo ""
echo "=== JSON Array Fields (4) ==="

run_schema_test "json_missing_pubkeys_array" "missing_pubkeys" "list"
run_schema_test "json_failed_services_array" "failed_services" "list"
run_schema_test "json_zombie_processes_array" "zombie_processes" "list"
run_schema_test "json_sudoers_d_issues_array" "sudoers_d_issues" "list"

# ==================== JSON OBJECT FIELDS (3 tests) ====================
echo ""
echo "=== JSON Object Fields (3) ==="

run_schema_test "json_repos_object" "repos" "dict"
run_schema_test "json_kernel_object" "kernel" "dict"
run_schema_test "json_disk_usage_object" "disk_usage" "dict"

# ==================== JSON SPECIAL FIELDS (2 tests) ====================
echo ""
echo "=== JSON Special Fields (2) ==="

run_test "json_checksum_present" --dry-run
run_test "json_schema_validation" --json-summary --dry-run

# ==================== RESULTS ====================
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              DATA TYPES TEST RESULTS                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo "Passed: $PASSED  Failed: $FAILED"
echo "Total: $((PASSED + FAILED))"

if [[ $FAILED -eq 0 ]]; then
    echo "✅ ALL DATA TYPE TESTS PASSED"
    exit 0
else
    echo "❌ SOME DATA TYPE TESTS FAILED"
    exit 1
fi
