#!/usr/bin/env bash
# lib/maintenance/storage.sh - Disk and storage management
# sysmaint library

crash_dump_purge() {
  if [[ "${CLEAR_CRASH_DUMPS:-true}" != "true" ]]; then
    log "--no-clear-crash requested: skipping crash dump purge."
    return 0
  fi
  log "=== Crash dump purge start ==="
  local targets=(/var/crash /var/lib/systemd/coredump)
  local total_before=0 total_after=0 freed=0 t
  for t in "${targets[@]}"; do
    [[ -d "$t" ]] || continue
    size=$(du -sb "$t" 2>/dev/null | awk '{print $1}')
    size=${size:-0}
    total_before=$((total_before + size))
  done

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    if command -v numfmt >/dev/null 2>&1; then
      log "Crash/coredump total size: $(numfmt --to=iec-i --suffix=B "$total_before" 2>/dev/null || echo "${total_before}B")"
    else
      log "Crash/coredump total size: ${total_before}B"
    fi
    CRASH_FREED_BYTES=$total_before
    log "=== Crash dump purge complete (dry-run) ==="
    return 0
  fi

  for t in "${targets[@]}"; do
    [[ -d "$t" ]] || continue
    if rm -rf "${t:?}"/* >>"$LOG_FILE" 2>&1; then
      :
    else
      log "Failed to purge $t (see $LOG_FILE)"
    fi
  done

  for t in "${targets[@]}"; do
    [[ -d "$t" ]] || continue
    size=$(du -sb "$t" 2>/dev/null | awk '{print $1}')
    size=${size:-0}
    total_after=$((total_after + size))
  done
  freed=$((total_before - total_after))
  CRASH_FREED_BYTES=$freed
  if command -v numfmt >/dev/null 2>&1; then
    log "Crash dumps purged. Freed: $(numfmt --to=iec-i --suffix=B "$freed" 2>/dev/null || echo "${freed}B")"
  else
    log "Crash dumps purged. Freed: ${freed}B"
  fi
  log "=== Crash dump purge complete ==="
}

fstrim_phase() {
  if [[ "${FSTRIM_ENABLED:-false}" != "true" ]]; then
    log "--fstrim not enabled; skipping filesystem TRIM."
    return 0
  fi
  if ! command -v fstrim >/dev/null 2>&1; then
    log "fstrim not available on this system; skipping."
    _skip_cap "fstrim_phase" "fstrim"
    return 0
  fi
  log "=== Filesystem TRIM start ==="
  TRIMMED_FILESYSTEMS=()
  FSTRIM_TOTAL_TRIMMED=0
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "DRY_RUN: would run: fstrim -av"
    log "=== Filesystem TRIM complete (dry-run) ==="
    return 0
  fi
  # Capture output: lines like '/: 12345 bytes trimmed'
  set +e
  trim_out=$(fstrim -av 2>&1)
  rc=$?
  set -e
  printf '%s
' "$trim_out" | tee -a "$LOG_FILE" >/dev/null
  while IFS= read -r line; do
    # Try to parse: mount: N bytes trimmed
    if [[ "$line" =~ ^([^:]+):[[:space:]]+([0-9]+)[[:space:]]+bytes[[:space:]]+trimmed ]]; then
      mnt="${BASH_REMATCH[1]}"
      bytes="${BASH_REMATCH[2]}"
      TRIMMED_FILESYSTEMS+=("$mnt: $bytes")
      FSTRIM_TOTAL_TRIMMED=$((FSTRIM_TOTAL_TRIMMED + bytes))
    fi
  done <<< "$trim_out"
  if command -v numfmt >/dev/null 2>&1; then
    log "fstrim total freed: $(numfmt --to=iec-i --suffix=B "$FSTRIM_TOTAL_TRIMMED" 2>/dev/null || echo "${FSTRIM_TOTAL_TRIMMED}B")"
  else
    log "fstrim total freed: ${FSTRIM_TOTAL_TRIMMED}B"
  fi
  if (( ${#TRIMMED_FILESYSTEMS[@]} > 0 )); then
    log "Trimmed filesystems: ${TRIMMED_FILESYSTEMS[*]}"
  fi
  log "=== Filesystem TRIM complete ==="
  return $rc
}

drop_caches_phase() {
  if [[ "${DROP_CACHES_ENABLED:-false}" != "true" ]]; then
    log "drop_caches_phase: disabled (set DROP_CACHES_ENABLED=true or --drop-caches)."
    return 0
  fi
  log "=== Drop caches phase start ==="
  # Memory snapshot helpers
  _mem_snapshot() {
    awk '/MemAvailable/ {print $2}' /proc/meminfo 2>/dev/null || echo 0
  }
  _swap_snapshot() {
    awk '/SwapFree/ {print $2}' /proc/meminfo 2>/dev/null || echo 0
  }
  MEM_BEFORE_KB=$(_mem_snapshot)
  SWAP_BEFORE_KB=$(_swap_snapshot)
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "DRY_RUN: would sync && echo 3 > /proc/sys/vm/drop_caches"
    if [[ "${DROP_CACHES_SWAP_RECYCLE:-false}" == "true" ]]; then
      log "DRY_RUN: would perform swapoff -a && swapon -a"
    fi
    MEM_AFTER_KB=$MEM_BEFORE_KB
    SWAP_AFTER_KB=$SWAP_BEFORE_KB
    log "=== Drop caches phase complete (dry-run) ==="
    return 0
  fi
  # Require root (already enforced earlier) but double-check safety
  if [[ $EUID -ne 0 ]]; then
    log "drop_caches_phase: requires root privileges; skipping."
    return 0
  fi
  sync || true
  if echo 3 > /proc/sys/vm/drop_caches 2>>"$LOG_FILE"; then
    log "Kernel caches dropped (pagecache,dentries,inodes)."
  else
    log "Failed to drop caches (see $LOG_FILE)"
  fi
  if [[ "${DROP_CACHES_SWAP_RECYCLE:-false}" == "true" ]]; then
    if command -v swapoff >/dev/null 2>&1; then
      if swapoff -a 2>>"$LOG_FILE" && swapon -a 2>>"$LOG_FILE"; then
        log "Swap recycled (swapoff -a && swapon -a)."
      else
        log "Swap recycle encountered errors (see $LOG_FILE)."
      fi
    else
      log "swapoff/swapon not found; skipping swap recycle."
    fi
  fi
  MEM_AFTER_KB=$(_mem_snapshot)
  SWAP_AFTER_KB=$(_swap_snapshot)
  local freed_mem=$((MEM_AFTER_KB - MEM_BEFORE_KB))
  if command -v numfmt >/dev/null 2>&1; then
    log "MemAvailable delta: $(numfmt --to=iec-i --suffix=B $((MEM_BEFORE_KB*1024)) 2>/dev/null) -> $(numfmt --to=iec-i --suffix=B $((MEM_AFTER_KB*1024)) 2>/dev/null) (Δ ${freed_mem}kB)"
  else
    log "MemAvailable delta: ${MEM_BEFORE_KB}kB -> ${MEM_AFTER_KB}kB (Δ ${freed_mem}kB)"
  fi
  log "=== Drop caches phase complete ==="
}
