#!/usr/bin/env bash
# lib/validation/repos.sh - Repository validation and management
# sysmaint library

validate_repos() {
  log "=== Repository validation start ==="
  # Current codename (e.g., focal, jammy)
  local codename
  codename=$(lsb_release -cs 2>/dev/null || echo "")
  
  # Detect distro for mirror diagnostics
  local distro_id=""
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    distro_id="${ID:-}"
  fi
  
  # Optional mirror diagnostics: check latency for primary mirrors
  if command -v curl >/dev/null 2>&1; then
    local primary_mirrors=()
    
    case "$distro_id" in
      ubuntu)
        primary_mirrors=("http://archive.ubuntu.com/ubuntu" "http://security.ubuntu.com/ubuntu" "http://us.archive.ubuntu.com/ubuntu")
        ;;
      debian)
        primary_mirrors=("http://deb.debian.org/debian" "http://security.debian.org/debian-security" "http://ftp.debian.org/debian")
        ;;
      linuxmint)
        primary_mirrors=("http://packages.linuxmint.com" "http://archive.ubuntu.com/ubuntu")
        ;;
      pop)
        primary_mirrors=("http://apt.pop-os.org/proprietary" "http://archive.ubuntu.com/ubuntu")
        ;;
      *)
        # Fallback: Ubuntu mirrors for debian-like systems
        primary_mirrors=("http://archive.ubuntu.com/ubuntu" "http://security.ubuntu.com/ubuntu")
        ;;
    esac
    
    log "Mirror diagnostics for distro: ${distro_id:-unknown}"
    for mirror in "${primary_mirrors[@]}"; do
      local latency_ms
      latency_ms=$(curl -o /dev/null -s -w '%{time_total}\n' --max-time 5 "${mirror}/dists/" 2>/dev/null | awk '{print int($1 * 1000)}' || echo "timeout")
      if [[ "$latency_ms" == "timeout" ]]; then
        log "Mirror diagnostic: $mirror - timeout or unreachable"
      else
        log "Mirror diagnostic: $mirror - ${latency_ms}ms"
      fi
    done
  fi

  # Collect source files
  local src_files
  src_files=(/etc/apt/sources.list /etc/apt/sources.list.d/*.list)

  # Track checked URIs to avoid duplicate checks
  declare -A checked

  for f in "${src_files[@]}"; do
    [[ -r "$f" ]] || continue
    while IFS= read -r line || [[ -n "$line" ]]; do
      # Strip leading/trailing whitespace
      line="$(printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
      # Skip blanks and comments
      [[ -z "$line" || "$line" == \#* ]] && continue
      # Only handle deb (not deb-src)
      if [[ "$line" != deb* ]]; then
        continue
      fi

      # Tokenize respecting options in []
      # Examples:
      # deb http://archive.ubuntu.com/ubuntu jammy main
      # deb [arch=amd64] http://ppa.launchpad.net/foo/ubuntu jammy main
      read -r _ tok1 tok2 tok3 <<<"$line"
      local uri dist
      if [[ "$tok1" == \[* ]]; then
        uri="$tok2"
        dist="$tok3"
      else
        uri="$tok1"
        dist="$tok2"
      fi

      # Normalize uri (remove trailing /)
      uri="${uri%/}"
      # Skip non-http(s) URIs (file: or cdrom: or deb) - still attempt http only
      if [[ ! "$uri" =~ ^https?:// ]]; then
        log "Skipping non-HTTP repository: $uri"
        continue
      fi

      # Avoid re-checking same uri+dist
      key="$uri|$dist"
      if [[ -n "${checked[$key]:-}" ]]; then
        continue
      fi
      checked[$key]=1

      # Try to fetch the Release file for the suite
      local release_url
      release_url="$uri/dists/$dist/Release"
      if curl -sSf --head "$release_url" >/dev/null 2>&1; then
        if [[ -n "$codename" && "$dist" != "$codename" ]]; then
          log "Repository mismatch: $uri uses dist '$dist' (system: $codename)"
          REPO_MISMATCH+=("$uri|$dist")
        else
          log "Repository OK: $uri (suite: $dist)"
          REPO_OK+=("$uri|$dist")
        fi
      else
        log "Repository unreachable or Release missing: $uri (suite: $dist)"
        REPO_FAIL+=("$uri|$dist")
      fi
    done <"$f"
  done

  log "=== Repository validation complete ==="
}
