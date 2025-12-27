#!/usr/bin/bash
# lib/reporting/reboot.sh
# stable: Reboot handling and notification

reboot_if_required() {
  if [[ -f /var/run/reboot-required ]]; then
    log "Reboot required. Packages: $(cat /var/run/reboot-required.pkgs 2>/dev/null || echo 'kernel/critical updates')"
    if [[ "$AUTO_REBOOT" == "true" ]]; then
      if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log "DRY_RUN: AUTO_REBOOT requested — would reboot in ${AUTO_REBOOT_DELAY}s"
      else
        log "AUTO_REBOOT=true -> Rebooting in ${AUTO_REBOOT_DELAY}s..."
        sleep "${AUTO_REBOOT_DELAY}"
        /sbin/reboot
      fi
    else
      log "Auto-reboot disabled. Please reboot when convenient."
    fi
  else
    log "No reboot required."
  fi
}
