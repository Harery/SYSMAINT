#!/usr/bin/env bash
# lib/validation/keys.sh - GPG/APT public key management
# sysmaint library

detect_missing_pubkeys() {
  log "=== Checking for missing APT repository public keys (NO_PUBKEY) ==="
  
  # This is APT/Debian-specific - skip on other distros
  if [[ "$PKG_MANAGER_TYPE" != "apt" ]]; then
    log "Skipping NO_PUBKEY detection (only applicable to APT-based systems)"
    return 0
  fi
  
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "DRY_RUN: skipping NO_PUBKEY detection. Re-run without --dry-run to perform detection."
    NO_PUBKEY_SKIPPED=true
    return 0
  fi

  local sim_file tmp_out update_out rc raw_keys key
  tmp_out="$LOG_DIR/apt_update_for_keys_${RUN_ID}.txt"

  # Run apt-get update and capture both stdout/stderr for analysis.
  set +e
  update_out=$(apt-get update 2>&1)
  rc=$?
  set -e

  # Save the update output to the run log and a separate file for later inspection
  printf '%s\n' "$update_out" | tee -a "$LOG_FILE" >"$tmp_out" || true

  # Extract NO_PUBKEY fingerprints (common apt message: "NO_PUBKEY <HEX>")
  raw_keys=$(printf '%s\n' "$update_out" | grep -oE 'NO_PUBKEY[[:space:]]+[0-9A-Fa-f]+' || true)
  if [[ -z "$raw_keys" ]]; then
    log "No missing public key errors detected in apt-get update output."
    return $rc
  fi

  # Normalize into unique hex-only keys
  while IFS= read -r line; do
    key=$(printf '%s' "$line" | awk '{print $2}' | tr '[:lower:]' '[:upper:]')
    if [[ -n "$key" ]]; then
      MISSING_PUBKEYS+=("$key")
    fi
  done < <(printf '%s\n' "$raw_keys")

  # Deduplicate
  if ((${#MISSING_PUBKEYS[@]})); then
    IFS=$'\n' read -r -d '' -a MISSING_PUBKEYS < <(printf '%s\n' "${MISSING_PUBKEYS[@]}" | awk '!x[$0]++' && printf '\0')
    log "Detected missing public keys: ${MISSING_PUBKEYS[*]}"
    for key in "${MISSING_PUBKEYS[@]}"; do
      log "Suggested remediation for key $key:"
      log "  - If using apt-key (deprecated): sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $key"
      log "  - Recommended alternative (fetch and install to /etc/apt/trusted.gpg.d):"
  log "    curl -fsSL \"https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x${key}\" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/${key}.gpg >/dev/null"
    done
  fi
  return $rc
}

fix_missing_pubkeys() {
  log "=== Fix missing APT public keys (interactive) ==="

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "DRY_RUN: skipping key installation. Re-run without --dry-run and with --fix-missing-keys to apply fixes."
    return 0
  fi

  if [[ ${#MISSING_PUBKEYS[@]} -eq 0 ]]; then
    log "No missing public keys recorded; running detection now."
    detect_missing_pubkeys || true
  fi

  if [[ ${#MISSING_PUBKEYS[@]} -eq 0 ]]; then
    log "No missing public keys found; nothing to fix."
    return 0
  fi

  if [[ $EUID -ne 0 ]]; then
    log "ERROR: --fix-missing-keys is root-only. Please run with sudo." && return 1
  fi

  for key in "${MISSING_PUBKEYS[@]}"; do
    # Prompt the user for each key
    if [[ "${ASSUME_YES:-false}" == "true" ]]; then
      ans=y
    else
      while true; do
        printf '\nInstall missing APT key %s? [y/N]: ' "$key" >&2
        read -r ans
        case "${ans:-}" in
        y|Y)
          break
          ;;
        n|N|"")
          ans=n
          break
          ;;
        *) printf 'Please answer y or n.\n'
          ;;
        esac
      done
    fi

    if [[ "${ans,,}" == "y" ]]; then
      log "Attempting to fetch and install key $key from $KEYSERVER"
  if curl -fsSL "https://$KEYSERVER/pks/lookup?op=get&search=0x${key}" | gpg --dearmor -o "/etc/apt/trusted.gpg.d/${key}.gpg" 2>>"$LOG_FILE"; then
        log "Installed key $key to /etc/apt/trusted.gpg.d/${key}.gpg"
      else
        log "Failed to install key $key using $KEYSERVER. Suggest manual remediation:"
        log "  sudo apt-key adv --keyserver $KEYSERVER --recv-keys $key"
        log "  or fetch and place into /etc/apt/trusted.gpg.d/ as a .gpg file"
      fi
    else
      log "Skipping key $key"
    fi
  done

  # Offer to run apt-get update to refresh after installing keys
  if [[ "${ASSUME_YES:-false}" == "true" ]]; then
    ans2=y
  else
    while true; do
      printf '\nRun apt-get update now to refresh package metadata? [y/N]: ' >&2
      read -r ans2
      case "${ans2:-}" in
      y|Y)
        break
        ;;
      n|N|"")
        break
        ;;
      *) printf 'Please answer y or n.\n'
        ;;
      esac
    done
  fi

  if [[ "${ans2,,}" == "y" ]]; then
    log "Running apt-get update to refresh metadata"
    set +e
    apt-get update 2>&1 | tee -a "$LOG_FILE"
    set -e
  else
    log "Skipping apt-get update as requested"
  fi
}
