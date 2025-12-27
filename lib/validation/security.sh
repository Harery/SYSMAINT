#!/usr/bin/env bash
# lib/validation/security.sh - Security audits and system health
# sysmaint library

security_audit() {
  if [[ "${SECURITY_AUDIT_ENABLED:-false}" != "true" ]]; then
    return 0
  fi
  log "=== Security audit start ==="
  SUDOERS_D_ISSUES=()
  # Helper to check perms user:group:mode
  _check_perm() {
    local path="$1" mode_allowed="$3"
    if [[ ! -e "$path" ]]; then
      echo "missing"
      return 0
    fi
    local ugm
    ugm=$(stat -c '%U:%G:%a' "$path" 2>/dev/null || echo "unknown:unknown:0")
    local u=${ugm%%:*}
    local g=${ugm#*:}; g=${g%%:*}
    local m=${ugm##*:}
    # owner must be root and mode one of allowed (comma-separated)
    if [[ "$u" != "root" ]]; then echo "bad_owner:$ugm"; return 0; fi
    local ok=false
    IFS=',' read -r -a modes <<<"$mode_allowed"
    for mm in "${modes[@]}"; do [[ "$m" == "$mm" ]] && ok=true; done
    if [[ "$ok" != true ]]; then echo "bad_mode:$ugm"; else echo "ok:$ugm"; fi
  }

  local res
  res=$(_check_perm /etc/shadow root:root 600); [[ "$res" == ok:* ]] && SHADOW_PERMS_OK=true || SHADOW_PERMS_OK=false
  res=$(_check_perm /etc/gshadow root:root 600); [[ "$res" == ok:* ]] && GSHADOW_PERMS_OK=true || GSHADOW_PERMS_OK=false
  res=$(_check_perm /etc/sudoers root:root 440,400); [[ "$res" == ok:* ]] && SUDOERS_PERMS_OK=true || SUDOERS_PERMS_OK=false

  if [[ -d /etc/sudoers.d ]]; then
    while IFS= read -r -d '' f; do
      res=$(_check_perm "$f" root:root 440,400)
      if [[ "$res" != ok:* ]]; then
        SUDOERS_D_ISSUES+=("$f:$res")
      fi
    done < <(find /etc/sudoers.d -type f -print0 2>/dev/null)
  fi
  log "Security audit results: shadow_ok=$SHADOW_PERMS_OK gshadow_ok=$GSHADOW_PERMS_OK sudoers_ok=$SUDOERS_PERMS_OK sudoers.d_issues=${#SUDOERS_D_ISSUES[@]}"
  log "=== Security audit complete ==="
}

health_checks() {
  log "=== Pre-flight health checks ==="
  
  # Check disk space (root filesystem)
  local available_gb
  available_gb=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
  if [[ "$available_gb" -lt 5 ]]; then
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
      # In DRY_RUN, do not fail CI or preview runs due to space; just warn
      log "DRY_RUN: Low disk space (${available_gb}GB < 5GB) — continuing"
    else
      log "ERROR: Insufficient disk space. Available: ${available_gb}GB, Required: 5GB minimum"
      log "Free up disk space before running maintenance"
      return 1
    fi
  else
    log "Disk space check: ${available_gb}GB available (OK)"
  fi
  
  # Check /boot space if it exists as separate partition
  if df /boot >/dev/null 2>&1; then
    local boot_avail_mb
    boot_avail_mb=$(df -BM /boot | awk 'NR==2 {print $4}' | sed 's/M//')
    if [[ "$boot_avail_mb" -lt 100 ]]; then
      log "WARNING: Low /boot space. Available: ${boot_avail_mb}MB"
      log "Consider cleaning old kernels: apt autoremove --purge"
    else
      log "/boot space check: ${boot_avail_mb}MB available (OK)"
    fi
  fi
  
  # Check internet connectivity (if not in dry-run)
  if [[ "${DRY_RUN:-false}" != "true" ]]; then
    if ! ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
      log "WARNING: No internet connectivity detected"
      log "Network operations may fail"
    else
      log "Network connectivity check: OK"
    fi
  fi
  
  # Check system load
  local load_avg
  load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
  local cpu_count
  cpu_count=$(nproc)
  local load_threshold=$((cpu_count * 2))
  
  if command -v bc >/dev/null 2>&1; then
    local load_high
    load_high=$(echo "$load_avg > $load_threshold" | bc)
    if [[ "$load_high" == "1" ]]; then
      log "WARNING: High system load: $load_avg (threshold: $load_threshold)"
      log "Consider running maintenance during off-peak hours"
    else
      log "System load check: $load_avg (OK)"
    fi
  fi
  
  log "=== Health checks complete ==="
  return 0
}
