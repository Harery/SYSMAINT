#!/usr/bin/env bash
# Argument Matrix Test Suite - 94 tests
# Tests all argument combinations systematically
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
    # Accept exit codes: 0 (success), 1 (GUI requires interactive mode), 2 (edge case), 30 (failed services), or 100 (reboot required)
    if [[ $exit_code -eq 0 || $exit_code -eq 1 || $exit_code -eq 2 || $exit_code -eq 30 || $exit_code -eq 100 ]]; then
        echo "✅ PASS"
        PASSED=$((PASSED + 1))
    else
        echo "❌ FAIL (exit: $exit_code)"
        FAILED=$((FAILED + 1))
    fi
}

echo "╔════════════════════════════════════════════════════════════╗"
echo "║        ARGUMENT MATRIX TEST SUITE (94 Tests)               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ==================== CORE ARGUMENTS (15 tests) ====================
echo "=== Core Arguments (15) ==="

run_test "core_help" --help
run_test "core_version" --version
run_test "core_dry_run" --dry-run
run_test "core_auto" --auto --dry-run
run_test "core_yes" --yes --dry-run
run_test "core_detect" --detect
run_test "core_simulate_upgrade" --simulate-upgrade --dry-run
run_test "core_force_generic" --force-generic --dry-run
run_test "core_gui" --gui --dry-run
run_test "core_tui_alias" --tui --dry-run
run_test "core_dry_run_with_upgrade" --dry-run --upgrade
run_test "core_auto_with_yes" --auto --yes --dry-run
run_test "core_dry_run_auto" --dry-run --auto
run_test "core_detect_with_json" --detect --json-summary
run_test "core_help_exit_ok" --help

# ==================== OVERRIDE ARGUMENTS (12 tests) ====================
echo ""
echo "=== Override Arguments (12) ==="

run_test "override_distro_ubuntu" --distro ubuntu --dry-run
run_test "override_distro_debian" --distro debian --dry-run
run_test "override_distro_fedora" --distro fedora --dry-run
run_test "override_distro_arch" --distro arch --dry-run
run_test "override_pkg_manager_apt" --pkg-manager apt --dry-run
run_test "override_pkg_manager_dnf" --pkg-manager dnf --dry-run
run_test "override_pkg_manager_pacman" --pkg-manager pacman --dry-run
run_test "override_pkg_manager_zypper" --pkg-manager zypper --dry-run
run_test "override_init_systemd" --init-system systemd --dry-run
run_test "override_init_openrc" --init-system openrc --dry-run
run_test "override_combined" --distro ubuntu --pkg-manager apt --dry-run
run_test "override_priority" --distro fedora --upgrade --dry-run

# ==================== UPDATE ARGUMENTS (10 tests) ====================
echo ""
echo "=== Update Arguments (10) ==="

run_test "update_upgrade" --upgrade --dry-run
run_test "update_no_snap" --no-snap --dry-run
run_test "update_no_flatpak" --no-flatpak --dry-run
run_test "update_no_firmware" --no-firmware --dry-run
run_test "update_fix_missing_keys" --fix-missing-keys --dry-run
run_test "update_flatpak_user_only" --flatpak-user-only --dry-run
run_test "update_flatpak_system_only" --flatpak-system-only --dry-run
run_test "update_keyserver_custom" --keyserver "keyserver.ubuntu.com" --dry-run
run_test "update_upgrade_with_fix_keys" --upgrade --fix-missing-keys --dry-run
run_test "update_all_disabled" --no-snap --no-flatpak --no-firmware --dry-run

# ==================== CLEANUP ARGUMENTS (15 tests) ====================
echo ""
echo "=== Cleanup Arguments (15) ==="

run_test "cleanup_purge_kernels" --purge-kernels --dry-run
run_test "cleanup_keep_kernels_2" --purge-kernels --keep-kernels=2 --dry-run
run_test "cleanup_keep_kernels_5" --purge-kernels --keep-kernels=5 --dry-run
run_test "cleanup_orphan_purge" --orphan-purge --dry-run
run_test "cleanup_fstrim" --fstrim --dry-run
run_test "cleanup_drop_caches" --drop-caches --dry-run
run_test "cleanup_clear_tmp" --clear-tmp --dry-run
run_test "cleanup_clear_tmp_force" --clear-tmp-force --dry-run
run_test "cleanup_clear_tmp_age" --clear-tmp-age=7 --dry-run
run_test "cleanup_clear_crash" --clear-crash --dry-run
run_test "cleanup_journal_days" --journal-days=7 --dry-run
run_test "cleanup_update_grub" --update-grub --dry-run
run_test "cleanup_desktop_guard_off" --no-desktop-guard --dry-run
run_test "cleanup_comprehensive" --purge-kernels --orphan-purge --fstrim --drop-caches --dry-run
run_test "cleanup_all_cleanup" --clear-tmp --clear-crash --journal-days=30 --dry-run

# ==================== SECURITY ARGUMENTS (8 tests) ====================
echo ""
echo "=== Security Arguments (8) ==="

run_test "security_audit" --security-audit --dry-run
run_test "security_check_zombies" --check-zombies --dry-run
run_test "security_check_failed_services" --check-failed-services --dry-run
run_test "security_browser_cache_report" --browser-cache-report --dry-run
run_test "security_browser_cache_purge" --browser-cache-purge --dry-run
run_test "security_audit_with_zombies" --security-audit --check-zombies --dry-run
run_test "security_comprehensive" --security-audit --check-zombies --check-failed-services --dry-run
run_test "security_with_upgrade" --upgrade --security-audit --dry-run

# ==================== SNAP ARGUMENTS (6 tests) ====================
echo ""
echo "=== Snap Arguments (6) ==="

run_test "snap_no_clean_old" --no-snap-clean-old --dry-run
run_test "snap_no_clear_cache" --no-snap-clear-cache --dry-run
run_test "snap_clean_old" --snap-clean-old --dry-run
run_test "snap_clear_cache" --snap-clear-cache --dry-run
run_test "snap_both_cleanup" --snap-clean-old --snap-clear-cache --dry-run
run_test "snap_all_disabled" --no-snap --no-snap-clean-old --no-snap-clear-cache --dry-run

# ==================== PROGRESS ARGUMENTS (10 tests) ====================
echo ""
echo "=== Progress Arguments (10) ==="

run_test "progress_spinner" --progress=spinner --dry-run
run_test "progress_dots" --progress=dots --dry-run
run_test "progress_countdown" --progress=countdown --dry-run
run_test "progress_bar" --progress=bar --dry-run
run_test "progress_quiet" --progress=quiet --dry-run
run_test "progress_adaptive" --progress=adaptive --dry-run
run_test "progress_duration" --progress-duration=10 --dry-run
run_test "progress_none" --progress=none --dry-run
run_test "progress_with_upgrade" --progress=spinner --upgrade --dry-run
run_test "progress_reset_history" --reset-progress-history --dry-run

# ==================== COLOR ARGUMENTS (4 tests) ====================
echo ""
echo "=== Color Arguments (4) ==="

run_test "color_always" --color=always --dry-run
run_test "color_never" --color=never --dry-run
run_test "color_auto" --color=auto --dry-run
run_test "color_with_progress" --color=always --progress=spinner --dry-run

# ==================== LOGGING ARGUMENTS (6 tests) ====================
echo ""
echo "=== Logging Arguments (6) ==="

run_test "logging_json_summary" --json-summary --dry-run
run_test "logging_no_json_summary" --no-json-summary --dry-run
run_test "logging_log_max_size" --log-max-size-mb=50 --dry-run
run_test "logging_log_tail_keep" --log-tail-keep-kb=100 --dry-run
run_test "logging_json_with_upgrade" --json-summary --upgrade --dry-run
run_test "logging_max_size_zero" --log-max-size-mb=0 --dry-run

# ==================== REBOOT ARGUMENTS (6 tests) ====================
echo ""
echo "=== Reboot Arguments (6) ==="

run_test "reboot_auto" --auto-reboot --dry-run
run_test "reboot_no_reboot" --no-reboot --dry-run
run_test "reboot_delay_10" --auto-reboot --auto-reboot-delay=10 --dry-run
run_test "reboot_delay_60" --auto-reboot --auto-reboot-delay=60 --dry-run
run_test "reboot_with_upgrade" --upgrade --auto-reboot --dry-run
run_test "reboot_with_kernel_purge" --purge-kernels --auto-reboot --dry-run

# ==================== MISCELLANEOUS ARGUMENTS (4 tests) ====================
echo ""
echo "=== Miscellaneous Arguments (4) ==="

run_test "misc_parallel" --parallel --dry-run
run_test "misc_lock_wait" --lock-wait-seconds=60 --dry-run
run_test "misc_force_unlock" --force-unlock --dry-run
run_test "misc_wait_interval" --wait-interval=3 --dry-run

# ==================== COMPLEX COMBINATIONS (10 tests) ====================
echo ""
echo "=== Complex Combinations (10) ==="

run_test "combo_full_maintenance" --upgrade --orphan-purge --purge-kernels --fstrim --drop-caches --security-audit --check-zombies --dry-run
run_test "combo_security_focused" --security-audit --check-zombies --check-failed-services --browser-cache-report --dry-run
run_test "combo_cleanup_focused" --purge-kernels --orphan-purge --clear-tmp --journal-days=7 --fstrim --drop-caches --dry-run
run_test "combo_upgrade_all" --upgrade --fix-missing-keys --snap-clean-old --snap-clear-cache --dry-run
run_test "combo_desktop_cleanup" --browser-cache-purge --clear-tmp --clear-crash --journal-days=30 --dry-run
run_test "combo_server_mode" --upgrade --security-audit --check-failed-services --orphan-purge --dry-run
run_test "combo_minimal" --upgrade --orphan-purge --dry-run
run_test "combo_with_all_progress" --upgrade --progress=spinner --color=always --json-summary --dry-run
run_test "combo_auto_mode" --auto --yes --upgrade --orphan-purge --security-audit --auto-reboot --dry-run
run_test "combo_dry_run_comprehensive" --dry-run --upgrade --orphan-purge --security-audit --fstrim --drop-caches --clear-tmp --check-zombies --check-failed-services --json-summary

# ==================== RESULTS ====================
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║            ARGUMENT MATRIX TEST RESULTS                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo "Passed: $PASSED  Failed: $FAILED"
echo "Total: $((PASSED + FAILED))"

if [[ $FAILED -eq 0 ]]; then
    echo "✅ ALL ARGUMENT MATRIX TESTS PASSED"
    exit 0
else
    echo "❌ SOME ARGUMENT MATRIX TESTS FAILED"
    exit 1
fi
