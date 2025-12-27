#!/usr/bin/env bash
# lib/validation/services.sh - Service and process health checks
# sysmaint library

check_failed_services() {
  if ! command -v systemctl >/dev/null 2>&1; then
    log "systemctl not available; skipping failed services check."
    return 0
  fi

  log "=== Checking for failed systemd services ==="
  
  if [[ "${CHECK_FAILED_SERVICES:-true}" != "true" ]]; then
    log "--no-check-failed-services requested: skipping."
    return 0
  fi

  local failed_services
  failed_services=$(systemctl --failed --no-legend --no-pager 2>/dev/null | awk '{print $1}' || true)

  if [[ -z "$failed_services" ]]; then
    log "No failed services detected"
  else
    log "WARNING: Failed services detected:"
    while IFS= read -r service; do
      log "  - $service"
      FAILED_SERVICES+=("$service")
    done <<< "$failed_services"
    log "Review failed services with: systemctl status <service-name>"
  fi

  log "=== Failed services check complete ==="
}

check_zombie_processes() {
  if [[ "${CHECK_ZOMBIES:-true}" != "true" ]]; then
    return 0
  fi
  ZOMBIE_PROCESSES=()
  ZOMBIE_COUNT=0
  # Iterate /proc for processes
  local pid state ppid name cmd
  for pid_dir in /proc/[0-9]*; do
    [[ -r "$pid_dir/status" ]] || continue
    pid=${pid_dir##*/}
    state=$(awk -F'\t' '/^State:/ {print $2}' "$pid_dir/status" 2>/dev/null | awk '{print $1}')
    if [[ "$state" == "Z" ]]; then
      ppid=$(awk -F'\t' '/^PPid:/ {print $2}' "$pid_dir/status" 2>/dev/null | tr -d ' ')
      name=$(awk -F'\t' '/^Name:/ {print $2}' "$pid_dir/status" 2>/dev/null | tr -d ' ')
      if [[ -r "$pid_dir/cmdline" ]]; then
        cmd=$(tr '\0' ' ' <"$pid_dir/cmdline" 2>/dev/null)
      else
        cmd="$name"
      fi
      ZOMBIE_PROCESSES+=("${pid}:${ppid}:${cmd}")
      ((ZOMBIE_COUNT++))
      if (( ZOMBIE_COUNT <= 50 )); then
        log "WARNING: zombie process detected pid=$pid ppid=$ppid cmd=$cmd"
      fi
    fi
  done
  if (( ZOMBIE_COUNT > 0 )); then
    log "Zombie processes detected: $ZOMBIE_COUNT"
  else
    log "No zombie processes detected"
  fi
}
