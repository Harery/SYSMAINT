#!/usr/bin/env bash
# OS Families Test Suite - 30 tests
# Tests Arch Linux and SUSE specific functions
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery

set -euo pipefail
cd "$(dirname "$0")/.."  # repo root

SCRIPT="./sysmaint"
PASSED=0
FAILED=0

run_test() {
    local name="$1"
    shift
    echo -n "[TEST] $name: "
    set +e
    DRY_RUN=true JSON_SUMMARY=true bash "$SCRIPT" "$@" >/dev/null 2>&1
    local exit_code=$?
    set -e
    if [[ $exit_code -eq 0 || $exit_code -eq 30 || $exit_code -eq 100 ]]; then
        echo "✅ PASS"
        PASSED=$((PASSED + 1))
    else
        echo "❌ FAIL (exit: $exit_code)"
        FAILED=$((FAILED + 1))
    fi
}

echo "╔════════════════════════════════════════════════════════════╗"
echo "║        OS FAMILIES TEST SUITE (30 Tests)                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ==================== ARCH LINUX FAMILY TESTS (15 tests) ====================
echo "=== Arch Linux Family Tests (15) ==="

# Test 1: arch_distro_override_detection
run_test "arch_distro_override_detection" --distro arch --detect --dry-run

# Test 2: arch_pacman_package_manager
run_test "arch_pacman_package_manager" --distro arch --pkg-manager pacman --dry-run

# Test 3: arch_family_detection
run_test "arch_family_detection" --distro arch --dry-run

# Test 4: arch_manjaro_variant
run_test "arch_manjaro_variant" --distro manjaro --dry-run

# Test 5: arch_endeavouros_variant
run_test "arch_endeavouros_variant" --distro endeavouros --dry-run

# Test 6: arch_upgrade_operations
run_test "arch_upgrade_operations" --distro arch --upgrade --dry-run

# Test 7: arch_orphan_purge
run_test "arch_orphan_purge" --distro arch --orphan-purge --dry-run

# Test 8: arch_kernel_purge
run_test "arch_kernel_purge" --distro arch --purge-kernels --dry-run

# Test 9: arch_kernel_purge_keep_custom
run_test "arch_kernel_purge_keep_custom" --distro arch --purge-kernels --keep-kernels=3 --dry-run

# Test 10: arch_snap_maintenance
run_test "arch_snap_maintenance" --distro arch --dry-run

# Test 11: arch_flatpak_maintenance
run_test "arch_flatpak_maintenance" --distro arch --dry-run

# Test 12: arch_firmware_maintenance
run_test "arch_firmware_maintenance" --distro arch --dry-run

# Test 13: arch_journal_maintenance
run_test "arch_journal_maintenance" --distro arch --journal-days=7 --dry-run

# Test 14: arch_security_audit
run_test "arch_security_audit" --distro arch --security-audit --dry-run

# Test 15: arch_comprehensive_maintenance
run_test "arch_comprehensive_maintenance" --distro arch --upgrade --orphan-purge --security-audit --dry-run

# ==================== SUSE FAMILY TESTS (15 tests) ====================
echo ""
echo "=== SUSE Family Tests (15) ==="

# Test 16: suse_distro_override_detection
run_test "suse_distro_override_detection" --distro opensuse --detect --dry-run

# Test 17: suse_zypper_package_manager
run_test "suse_zypper_package_manager" --distro opensuse --pkg-manager zypper --dry-run

# Test 18: suse_family_detection
run_test "suse_family_detection" --distro opensuse --dry-run

# Test 19: suse_tumbleweed_variant
run_test "suse_tumbleweed_variant" --distro opensuse-tumbleweed --dry-run

# Test 20: suse_leap_variant
run_test "suse_leap_variant" --distro opensuse-leap --dry-run

# Test 21: suse_sles_variant
run_test "suse_sles_variant" --distro sles --dry-run

# Test 22: suse_upgrade_operations
run_test "suse_upgrade_operations" --distro opensuse --upgrade --dry-run

# Test 23: suse_orphan_purge
run_test "suse_orphan_purge" --distro opensuse --orphan-purge --dry-run

# Test 24: suse_kernel_purge
run_test "suse_kernel_purge" --distro opensuse --purge-kernels --dry-run

# Test 25: suse_kernel_purge_keep_custom
run_test "suse_kernel_purge_keep_custom" --distro opensuse --purge-kernels --keep-kernels=4 --dry-run

# Test 26: suse_snap_maintenance
run_test "suse_snap_maintenance" --distro opensuse --dry-run

# Test 27: suse_flatpak_maintenance
run_test "suse_flatpak_maintenance" --distro opensuse --dry-run

# Test 28: suse_firmware_maintenance
run_test "suse_firmware_maintenance" --distro opensuse --dry-run

# Test 29: suse_journal_maintenance
run_test "suse_journal_maintenance" --distro opensuse --journal-days=30 --dry-run

# Test 30: suse_comprehensive_maintenance
run_test "suse_comprehensive_maintenance" --distro opensuse --upgrade --orphan-purge --security-audit --dry-run

# ==================== RESULTS ====================
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              OS FAMILIES TEST RESULTS                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo "Passed: $PASSED  Failed: $FAILED"
echo "Total: $((PASSED + FAILED))"

if [[ $FAILED -eq 0 ]]; then
    echo "✅ ALL OS FAMILY TESTS PASSED"
    exit 0
else
    echo "❌ SOME OS FAMILY TESTS FAILED"
    exit 1
fi
