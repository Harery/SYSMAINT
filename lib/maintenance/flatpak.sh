#!/usr/bin/env bash
# lib/maintenance/flatpak.sh - Flatpak package management
# sysmaint library

flatpak_maintenance() {
  if ! command -v flatpak >/dev/null 2>&1; then
    log "Flatpak not installed; skipping flatpak tasks."
    _skip_cap "flatpak_maintenance" "flatpak"
    return 0
  fi
  log "=== Flatpak maintenance start ==="
  
  if [[ "${NO_FLATPAK:-false}" == "true" ]]; then
    log "--no-flatpak requested: skipping flatpak update and cleanup."
    return 0
  fi

  # Determine scope: auto|user|system|both
  local scope="${FLATPAK_SCOPE:-auto}" update_cmds=()
  FLATPAK_SCOPE_APPLIED="$scope"
  case "$scope" in
    auto)
      # If running as root, prefer system; else user
      if [[ $EUID -eq 0 ]]; then
        update_cmds+=("flatpak update --system -y")
      else
        update_cmds+=("flatpak update --user -y")
      fi
      ;;
    user)
      update_cmds+=("flatpak update --user -y")
      ;;
    system)
      update_cmds+=("flatpak update --system -y")
      ;;
    both)
      update_cmds+=("flatpak update --user -y" "flatpak update --system -y")
      ;;
    *)
      log "Unknown FLATPAK_SCOPE '$scope' (expected auto|user|system|both); defaulting to auto"
      if [[ $EUID -eq 0 ]]; then
        update_cmds+=("flatpak update --system -y")
      else
        update_cmds+=("flatpak update --user -y")
      fi
      ;;
  esac

  # Update flatpaks per chosen scope
  for cmd in "${update_cmds[@]}"; do
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
      log "DRY_RUN: would run: $cmd"
    else
      log "Running: $cmd"
      if eval "$cmd" >>"$LOG_FILE" 2>&1; then
        log "Flatpak update scope succeeded: $cmd"
      else
        log "Flatpak update scope had errors: $cmd (see $LOG_FILE)"
      fi
    fi
  done

  # Remove unused runtimes per scope (user/system)
  local prune_scopes=()
  case "$scope" in
    auto)
      if [[ $EUID -eq 0 ]]; then
        prune_scopes+=("system")
      else
        prune_scopes+=("user")
      fi
      ;;
    user)
      prune_scopes+=("user")
      ;;
    system)
      prune_scopes+=("system")
      ;;
    both)
      prune_scopes+=("user" "system")
      ;;
  esac
  for ps in "${prune_scopes[@]}"; do
    local prune_cmd="flatpak uninstall --unused -y --$ps"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
      log "DRY_RUN: would run: $prune_cmd"
    else
      log "Removing unused flatpak runtimes ($ps scope)..."
      if eval "$prune_cmd" >>"$LOG_FILE" 2>&1; then
        log "Unused flatpak runtimes removed ($ps)"
      else
        log "No unused flatpak runtimes to remove or failed ($ps) (see $LOG_FILE)"
      fi
    fi
  done

  log "=== Flatpak maintenance complete ==="
}
