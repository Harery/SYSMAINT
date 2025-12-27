#!/usr/bin/env bash
# lib/core/detection.sh - Phase 3 Auto-Detection Functions
# sysmaint library
# Copyright (c) 2025 Mohamed Elharery

# Phase 3 Enhancement: Intelligent auto-detection of package managers, init systems,
# manual override support, and graceful fallback for unknown distributions.
#
# Functions:
#   detect_package_manager()    - Auto-discover package manager (apt/dnf/pacman/zypper)
#   detect_init_system()        - Auto-detect init system (systemd/OpenRC/sysvinit)
#   apply_manual_overrides()    - Process manual override flags
#   show_detection_report()     - Display detection results (--detect flag)
#   fallback_to_generic()       - Generic mode for unknown distributions
#   export_detection_vars()     - Export detection results for telemetry

# Global detection variables (exported for telemetry)
export DETECTED_OS_ID=""
export DETECTED_OS_NAME=""
export DETECTED_OS_VERSION=""
export DETECTED_OS_FAMILY=""
export DETECTED_PKG_MANAGER=""
export DETECTED_INIT_SYSTEM=""
export DETECTION_METHOD="auto"  # auto, manual-override, or fallback

# Phase 3: Auto-discover package manager
detect_package_manager() {
  local pm="unknown"
  
  # Check for package managers in priority order
  if command -v apt-get >/dev/null 2>&1 && command -v dpkg >/dev/null 2>&1; then
    pm="apt"
  elif command -v dnf >/dev/null 2>&1; then
    pm="dnf"
  elif command -v pacman >/dev/null 2>&1; then
    pm="pacman"
  elif command -v zypper >/dev/null 2>&1; then
    pm="zypper"
  elif command -v yum >/dev/null 2>&1; then
    pm="yum"
  elif command -v apk >/dev/null 2>&1; then
    pm="apk"
  fi
  
  echo "$pm"
}

# Phase 3: Auto-detect init system
detect_init_system() {
  local init="unknown"
  
  # Method 1: Check if systemctl is available and functional
  if command -v systemctl >/dev/null 2>&1; then
    if systemctl --version >/dev/null 2>&1 2>/dev/null; then
      init="systemd"
      echo "$init"
      return 0
    fi
  fi
  
  # Method 2: Check /sbin/init symlink
  if [[ -L /sbin/init ]]; then
    local init_target
    init_target=$(readlink /sbin/init)
    case "$init_target" in
      */systemd)
        init="systemd"
        ;;
      */openrc-init)
        init="openrc"
        ;;
      *)
        # Check if it's a traditional sysvinit
        if [[ "$init_target" == */init ]]; then
          init="sysvinit"
        fi
        ;;
    esac
  fi
  
  # Method 3: Check process 1
  if [[ "$init" == "unknown" ]] && [[ -d /proc/1 ]]; then
    local proc1_comm
    proc1_comm=$(cat /proc/1/comm 2>/dev/null || echo "")
    case "$proc1_comm" in
      systemd)
        init="systemd"
        ;;
      init|*init*)
        init="sysvinit"
        ;;
      openrc|*openrc*)
        init="openrc"
        ;;
    esac
  fi
  
  echo "$init"
}

# Phase 3: Apply manual overrides from command-line flags
apply_manual_overrides() {
  local override_applied=false
  
  # Override distribution
  if [[ -n "${OVERRIDE_DISTRO:-}" ]]; then
    DETECTED_OS_ID="$OVERRIDE_DISTRO"
    DETECTION_METHOD="manual-override"
    override_applied=true
    log "Manual override: OS ID = $OVERRIDE_DISTRO"
  fi
  
  # Override package manager
  if [[ -n "${OVERRIDE_PKG_MANAGER:-}" ]]; then
    case "${OVERRIDE_PKG_MANAGER}" in
      apt|dnf|pacman|zypper|yum|apk)
        DETECTED_PKG_MANAGER="$OVERRIDE_PKG_MANAGER"
        DETECTION_METHOD="manual-override"
        override_applied=true
        log "Manual override: Package manager = $OVERRIDE_PKG_MANAGER"
        ;;
      *)
        echo "ERROR: Invalid package manager override: ${OVERRIDE_PKG_MANAGER}" >&2
        echo "Valid options: apt, dnf, pacman, zypper, yum, apk" >&2
        exit 1
        ;;
    esac
  fi
  
  # Override init system
  if [[ -n "${OVERRIDE_INIT_SYSTEM:-}" ]]; then
    case "${OVERRIDE_INIT_SYSTEM}" in
      systemd|openrc|sysvinit)
        DETECTED_INIT_SYSTEM="$OVERRIDE_INIT_SYSTEM"
        DETECTION_METHOD="manual-override"
        override_applied=true
        log "Manual override: Init system = $OVERRIDE_INIT_SYSTEM"
        ;;
      *)
        echo "ERROR: Invalid init system override: ${OVERRIDE_INIT_SYSTEM}" >&2
        echo "Valid options: systemd, openrc, sysvinit" >&2
        exit 1
        ;;
    esac
  fi
  
  return 0
}

# Phase 3: Display comprehensive system detection report and exit
show_detection_report() {
  echo ""
  echo "╔════════════════════════════════════════════════════════════════════════════╗"
  echo "║              SYSMAINT v${SCRIPT_VERSION} - SYSTEM DETECTION REPORT                   ║"
  echo "╠════════════════════════════════════════════════════════════════════════════╣"
  
  # ═══ Operating System ═══
  echo "║                                                                            ║"
  echo "║  🐧 Operating System                                                       ║"
  echo "║  ────────────────────                                                      ║"
  printf "║  • ID:           %-57s ║\n" "${DETECTED_OS_ID}"
  printf "║  • Name:         %-57s ║\n" "${DETECTED_OS_NAME}"
  printf "║  • Version:      %-57s ║\n" "${DETECTED_OS_VERSION}"
  printf "║  • Family:       %-57s ║\n" "${DETECTED_OS_FAMILY}"
  printf "║  • Kernel:       %-57s ║\n" "$(uname -r 2>/dev/null || echo 'unknown')"
  printf "║  • Architecture: %-57s ║\n" "$(uname -m 2>/dev/null || echo 'unknown')"
  
  # ═══ System Components ═══
  echo "║                                                                            ║"
  echo "║  ⚙️  System Components                                                      ║"
  echo "║  ──────────────────                                                        ║"
  printf "║  • Package Manager:  %-53s ║\n" "${DETECTED_PKG_MANAGER}"
  printf "║  • Init System:      %-53s ║\n" "${DETECTED_INIT_SYSTEM}"
  printf "║  • Detection Method: %-53s ║\n" "${DETECTION_METHOD}"
  
  # ═══ Hardware - CPU ═══
  echo "║                                                                            ║"
  echo "║  🖥️  CPU Information                                                        ║"
  echo "║  ─────────────────                                                         ║"
  
  local cpu_model=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2 | sed 's/^[ \t]*//' | head -c 55 || echo "unknown")
  local cpu_physical=$(grep "physical id" /proc/cpuinfo 2>/dev/null | sort -u | wc -l)
  local cpu_logical=$(nproc 2>/dev/null || grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo "unknown")
  local cpu_cores_per_socket=$(lscpu 2>/dev/null | grep "^Core(s) per socket:" | awk '{print $NF}' || echo "unknown")
  local cpu_threads_per_core=$(lscpu 2>/dev/null | grep "^Thread(s) per core:" | awk '{print $NF}' || echo "1")
  local ht_status="Disabled"
  [[ "$cpu_threads_per_core" -gt 1 ]] && ht_status="Enabled (${cpu_threads_per_core}x)"
  
  printf "║  • Model:            %-50s ║\n" "$cpu_model"
  printf "║  • Physical CPUs:    %-50s ║\n" "$cpu_physical"
  printf "║  • Logical Cores:    %-50s ║\n" "$cpu_logical"
  printf "║  • Cores per Socket: %-50s ║\n" "$cpu_cores_per_socket"
  printf "║  • Hyperthreading:   %-50s ║\n" "$ht_status"
  
  # ═══ Hardware - Motherboard ═══
  echo "║                                                                            ║"
  echo "║  🔌 Motherboard Information                                                ║"
  echo "║  ─────────────────────────                                                 ║"
  
  # Get motherboard info from dmidecode (requires root) or sysfs
  local mb_vendor="Unknown"
  local mb_model="Unknown"
  local mb_version="Unknown"
  
  if command -v dmidecode >/dev/null 2>&1 && [[ $EUID -eq 0 ]]; then
    mb_vendor=$(dmidecode -s baseboard-manufacturer 2>/dev/null | head -1 || echo "Unknown")
    mb_model=$(dmidecode -s baseboard-product-name 2>/dev/null | head -1 || echo "Unknown")
    mb_version=$(dmidecode -s baseboard-version 2>/dev/null | head -1 || echo "Unknown")
  elif [[ -r /sys/devices/virtual/dmi/id/board_vendor ]]; then
    mb_vendor=$(cat /sys/devices/virtual/dmi/id/board_vendor 2>/dev/null || echo "Unknown")
    mb_model=$(cat /sys/devices/virtual/dmi/id/board_name 2>/dev/null || echo "Unknown")
    mb_version=$(cat /sys/devices/virtual/dmi/id/board_version 2>/dev/null || echo "Unknown")
  fi
  
  printf "║  • Vendor:       %-57s ║\n" "$mb_vendor"
  printf "║  • Model:        %-57s ║\n" "$mb_model"
  [[ "$mb_version" != "Unknown" && "$mb_version" != "" ]] && printf "║  • Version:      %-57s ║\n" "$mb_version"
  
  # CPU Socket information
  local cpu_socket="Unknown"
  if command -v dmidecode >/dev/null 2>&1 && [[ $EUID -eq 0 ]]; then
    cpu_socket=$(dmidecode -t processor 2>/dev/null | grep "Socket Designation" | head -1 | cut -d: -f2 | sed 's/^[ \t]*//' || echo "Unknown")
  fi
  printf "║  • CPU Socket:   %-57s ║\n" "$cpu_socket"
  
  # Memory slots information
  if command -v dmidecode >/dev/null 2>&1 && [[ $EUID -eq 0 ]]; then
    # Parse dmidecode output
    local dmi_output=$(dmidecode -t memory 2>/dev/null)
    local total_slots=$(echo "$dmi_output" | grep -c "^\s*Memory Device$" || echo "0")
    
    # Count slots with actual memory
    local used_slots=$(echo "$dmi_output" | grep "^\s*Size:" | grep -vE "No Module|Not Installed" | grep -cE "[0-9]+.*GB|[0-9]+.*MB" || echo "0")
    local unused_slots=$((total_slots - used_slots))
    
    printf "║  • Memory Slots: %-57s ║\n" "$total_slots total"
    printf "║    - Used:       %-57s ║\n" "$used_slots"
    printf "║    - Available:  %-57s ║\n" "$unused_slots"
    
    # Show populated slot details
    if [[ $used_slots -gt 0 ]]; then
      local slot_num=1
      local line_num=0
      local current_size="" current_type="" current_speed=""
      
      while IFS= read -r line; do
        if echo "$line" | grep -q "^\s*Memory Device$"; then
          # Start of new memory device
          current_size=""
          current_type=""
          current_speed=""
        elif echo "$line" | grep -q "^\s*Size:"; then
          current_size=$(echo "$line" | sed 's/^\s*Size:\s*//' | head -c 15)
        elif echo "$line" | grep -q "^\s*Type:" && ! echo "$line" | grep -qE "Type Detail|Error Correction"; then
          current_type=$(echo "$line" | sed 's/^\s*Type:\s*//' | head -c 15)
        elif echo "$line" | grep -q "^\s*Speed:" && ! echo "$line" | grep -q "Configured"; then
          current_speed=$(echo "$line" | sed 's/^\s*Speed:\s*//' | head -c 15)
          
          # When we have Speed, check if we should print this slot
          if [[ -n "$current_size" ]] && echo "$current_size" | grep -qE "[0-9]" && ! echo "$current_size" | grep -qE "No Module|Not Installed"; then
            printf "║    - Slot %d:     %-54s ║\n" "$slot_num" "$current_size, $current_type, $current_speed"
            slot_num=$((slot_num + 1))
          fi
          # Reset for next device
          current_size=""
          current_type=""
          current_speed=""
        fi
      done <<< "$dmi_output"
    fi
  else
    printf "║  • Memory Slots: %-57s ║\n" "Unavailable (requires root)"
  fi
  
  # VRM information (usually not available via software)
  printf "║  • VRM Info:     %-57s ║\n" "Not available via software"
  
  # ═══ Hardware - Memory ═══
  echo "║                                                                            ║"
  echo "║  💾 Memory Information                                                     ║"
  echo "║  ────────────────────                                                      ║"
  
  if [[ -r /proc/meminfo ]]; then
    local mem_total_kb=$(grep "^MemTotal:" /proc/meminfo | awk '{print $2}')
    local mem_available_kb=$(grep "^MemAvailable:" /proc/meminfo | awk '{print $2}')
    local mem_free_kb=$(grep "^MemFree:" /proc/meminfo | awk '{print $2}')
    local mem_total_gb=$(awk "BEGIN {printf \"%.2f\", $mem_total_kb/1024/1024}")
    local mem_available_gb=$(awk "BEGIN {printf \"%.2f\", $mem_available_kb/1024/1024}")
    local mem_free_gb=$(awk "BEGIN {printf \"%.2f\", $mem_free_kb/1024/1024}")
    local mem_used_kb=$((mem_total_kb - mem_available_kb))
    local mem_used_gb=$(awk "BEGIN {printf \"%.2f\", $mem_used_kb/1024/1024}")
    local mem_used_pct=$(awk "BEGIN {printf \"%.1f\", ($mem_used_kb/$mem_total_kb)*100}")
    
    printf "║  • Total:       %-58s ║\n" "${mem_total_gb} GB"
    printf "║  • Used:        %-58s ║\n" "${mem_used_gb} GB (${mem_used_pct}%)"
    printf "║  • Available:   %-58s ║\n" "${mem_available_gb} GB"
    printf "║  • Free:        %-58s ║\n" "${mem_free_gb} GB"
  else
    printf "║  • Memory info unavailable                                                 ║\n"
  fi
  
  # ═══ Hardware - Storage ═══
  echo "║                                                                            ║"
  echo "║  💿 Storage Information                                                    ║"
  echo "║  ─────────────────────                                                     ║"
  
  if command -v df >/dev/null 2>&1; then
    local root_info=$(df -h / 2>/dev/null | tail -1)
    local root_size=$(echo "$root_info" | awk '{print $2}')
    local root_used=$(echo "$root_info" | awk '{print $3}')
    local root_avail=$(echo "$root_info" | awk '{print $4}')
    local root_pct=$(echo "$root_info" | awk '{print $5}')
    
    printf "║  • Root Partition (/)                                                      ║\n"
    printf "║    - Size:  %-63s ║\n" "$root_size"
    printf "║    - Used:  %-63s ║\n" "$root_used ($root_pct)"
    printf "║    - Free:  %-63s ║\n" "$root_avail"
  else
    printf "║  • Storage info unavailable                                                ║\n"
  fi
  
  # ═══ Hardware - GPU ═══
  echo "║                                                                            ║"
  echo "║  🎮 GPU Information                                                        ║"
  echo "║  ─────────────────                                                         ║"
  
  if command -v lspci >/dev/null 2>&1; then
    local gpu_count=$(lspci 2>/dev/null | grep -i "VGA\|3D\|Display" | wc -l)
    if [[ $gpu_count -gt 0 ]]; then
      printf "║  • GPU Count: %-60s ║\n" "$gpu_count"
      local gpu_num=1
      while IFS= read -r gpu_line; do
        local gpu_full=$(echo "$gpu_line" | cut -d: -f3 | sed 's/^[ \t]*//')
        
        # Determine if integrated or dedicated
        local gpu_type="Dedicated"
        if echo "$gpu_line" | grep -qi "VGA"; then
          # Check if it's integrated by looking for Intel integrated or AMD APU patterns
          if echo "$gpu_full" | grep -qiE "Intel.*Integrated|Intel.*UHD|Intel.*Iris|AMD.*Vega.*Series|Radeon.*Vega|Cezanne|Renoir|Picasso|Raven"; then
            gpu_type="Integrated"
          fi
        fi
        
        # Extract vendor
        local vendor="Unknown"
        if echo "$gpu_full" | grep -qi "NVIDIA\|nVidia"; then
          vendor="NVIDIA"
        elif echo "$gpu_full" | grep -qi "AMD\|ATI"; then
          vendor="AMD"
        elif echo "$gpu_full" | grep -qi "Intel"; then
          vendor="Intel"
        fi
        
        # Extract GPU family and model
        local gpu_family="Unknown"
        local gpu_model="$gpu_full"
        
        if [[ "$vendor" == "NVIDIA" ]]; then
          if echo "$gpu_full" | grep -qiE "GeForce RTX [0-9]{4}"; then
            gpu_family=$(echo "$gpu_full" | grep -oE "GeForce RTX [0-9]{4}" | head -1)
            gpu_model=$(echo "$gpu_full" | sed 's/.*GeForce/GeForce/' | head -c 50)
          elif echo "$gpu_full" | grep -qiE "GeForce GTX [0-9]{3,4}"; then
            gpu_family=$(echo "$gpu_full" | grep -oE "GeForce GTX [0-9]{3,4}" | head -1)
            gpu_model=$(echo "$gpu_full" | sed 's/.*GeForce/GeForce/' | head -c 50)
          else
            gpu_model=$(echo "$gpu_full" | head -c 50)
          fi
        elif [[ "$vendor" == "AMD" ]]; then
          if echo "$gpu_full" | grep -qiE "Radeon RX [0-9]{3,4}"; then
            gpu_family=$(echo "$gpu_full" | grep -oE "Radeon RX [0-9]{3,4}" | head -1)
            gpu_model=$(echo "$gpu_full" | sed 's/.*Radeon/Radeon/' | head -c 50)
          elif echo "$gpu_full" | grep -qiE "Radeon.*Vega"; then
            gpu_family="Radeon Vega"
            gpu_model=$(echo "$gpu_full" | sed 's/.*Radeon/Radeon/' | head -c 50)
          else
            gpu_model=$(echo "$gpu_full" | head -c 50)
          fi
        elif [[ "$vendor" == "Intel" ]]; then
          if echo "$gpu_full" | grep -qiE "UHD Graphics [0-9]{3,4}"; then
            gpu_family=$(echo "$gpu_full" | grep -oE "UHD Graphics [0-9]{3,4}" | head -1)
            gpu_model=$(echo "$gpu_full" | head -c 50)
          elif echo "$gpu_full" | grep -qiE "Iris"; then
            gpu_family="Iris"
            gpu_model=$(echo "$gpu_full" | head -c 50)
          else
            gpu_model=$(echo "$gpu_full" | head -c 50)
          fi
        fi
        
        # Try to get VRAM (this is tricky without root, best effort)
        local vram="Unknown"
        if command -v nvidia-smi >/dev/null 2>&1 && [[ "$vendor" == "NVIDIA" ]]; then
          vram=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1 | awk '{printf "%.0f GB", $1/1024}')
        elif [[ -r /sys/class/drm/card${gpu_num}/device/mem_info_vram_total ]]; then
          local vram_bytes=$(cat /sys/class/drm/card${gpu_num}/device/mem_info_vram_total 2>/dev/null)
          [[ -n "$vram_bytes" ]] && vram=$(awk "BEGIN {printf \"%.2f GB\", $vram_bytes/1024/1024/1024}")
        fi
        
        printf "║  • GPU #%d:    %-60s ║\n" "$gpu_num" "$gpu_type"
        printf "║    - VRAM:    %-60s ║\n" "$vram"
        printf "║    - Vendor:  %-60s ║\n" "$vendor"
        [[ "$gpu_family" != "Unknown" ]] && printf "║    - Family:  %-60s ║\n" "$gpu_family"
        printf "║    - Model:   %-60s ║\n" "$gpu_model"
        
        ((gpu_num++))
      done <<< "$(lspci 2>/dev/null | grep -i "VGA\|3D\|Display")"
    else
      printf "║  • No GPU detected                                                         ║\n"
    fi
  else
    printf "║  • GPU info unavailable (lspci not found)                                  ║\n"
  fi
  
  # ═══ Security - TPM ═══
  echo "║                                                                            ║"
  echo "║  🔐 Security Information                                                   ║"
  echo "║  ──────────────────────                                                    ║"
  
  local tpm_status="Not Detected"
  if [[ -d /sys/class/tpm/tpm0 ]]; then
    tpm_status="✓ TPM Device Present (tpm0)"
  elif [[ -c /dev/tpm0 ]]; then
    tpm_status="✓ TPM Device Present (/dev/tpm0)"
  fi
  printf "║  • TPM Status:   %-57s ║\n" "$tpm_status"
  
  # ═══ Network Configuration ═══
  echo "║                                                                            ║"
  echo "║  🌐 Network Configuration                                                  ║"
  echo "║  ───────────────────────                                                   ║"
  
  # Get primary network interface
  local primary_if=$(ip route 2>/dev/null | grep default | head -1 | awk '{print $5}' || echo "unknown")
  
  if [[ "$primary_if" != "unknown" ]] && command -v ip >/dev/null 2>&1; then
    local ip_addr=$(ip -4 addr show "$primary_if" 2>/dev/null | grep inet | awk '{print $2}' | head -1 || echo "unknown")
    local ip_only=$(echo "$ip_addr" | cut -d/ -f1)
    local subnet=$(echo "$ip_addr" | cut -d/ -f2)
    local gateway=$(ip route 2>/dev/null | grep default | head -1 | awk '{print $3}' || echo "unknown")
    local dns_servers=$(grep "^nameserver" /etc/resolv.conf 2>/dev/null | awk '{print $2}' | tr '\n' ', ' | sed 's/,$//' || echo "unknown")
    
    # Determine if DHCP or static
    local ip_config="Manual/Static"
    if command -v nmcli >/dev/null 2>&1; then
      local nm_method=$(nmcli -t -f ipv4.method connection show "$primary_if" 2>/dev/null | cut -d: -f2)
      [[ "$nm_method" == "auto" ]] && ip_config="DHCP"
    elif [[ -f /var/lib/dhcp/dhclient.leases ]] || [[ -f /var/lib/dhclient/dhclient.leases ]]; then
      ip_config="DHCP (detected lease files)"
    fi
    
    printf "║  • Interface:    %-57s ║\n" "$primary_if"
    printf "║  • IP Address:   %-57s ║\n" "$ip_only"
    printf "║  • Subnet Mask:  %-57s ║\n" "/$subnet"
    printf "║  • Gateway:      %-57s ║\n" "$gateway"
    printf "║  • DNS Servers:  %-57s ║\n" "${dns_servers:0:57}"
    printf "║  • IP Config:    %-57s ║\n" "$ip_config"
  else
    printf "║  • Network info unavailable                                                ║\n"
  fi
  
  # ═══ User & Location ═══
  echo "║                                                                            ║"
  echo "║  👤 User & Location Information                                            ║"
  echo "║  ─────────────────────────────                                             ║"
  
  local current_user="${USER:-${LOGNAME:-unknown}}"
  local user_id=$(id -u 2>/dev/null || echo "unknown")
  local user_type="Normal User"
  [[ "$user_id" == "0" ]] && user_type="Root"
  [[ "$user_id" != "0" ]] && groups | grep -qE "sudo|wheel|admin" && user_type="Sudoer"
  
  local hostname=$(hostname 2>/dev/null || echo "unknown")
  local timezone=$(timedatectl 2>/dev/null | grep "Time zone" | awk '{print $3}' || cat /etc/timezone 2>/dev/null || echo "unknown")
  local current_time=$(date "+%Y-%m-%d %H:%M:%S %Z" 2>/dev/null || echo "unknown")
  local uptime_info=$(uptime -p 2>/dev/null | sed 's/up //' || echo "unknown")
  
  printf "║  • Username:     %-57s ║\n" "$current_user"
  printf "║  • User ID:      %-57s ║\n" "$user_id"
  printf "║  • User Type:    %-57s ║\n" "$user_type"
  printf "║  • Hostname:     %-57s ║\n" "$hostname"
  printf "║  • Timezone:     %-57s ║\n" "$timezone"
  printf "║  • Current Time: %-57s ║\n" "$current_time"
  printf "║  • Uptime:       %-57s ║\n" "$uptime_info"
  
  # ═══ Supported Features ═══
  echo "║                                                                            ║"
  echo "║  ✨ Supported Features                                                     ║"
  echo "║  ────────────────────                                                      ║"
  
  local snap_status="✗ Not Available"
  local flatpak_status="✗ Not Available"
  local fwupd_status="✗ Not Available"
  
  if command -v snap >/dev/null 2>&1; then
    snap_status="✓ Available"
  fi
  if command -v flatpak >/dev/null 2>&1; then
    flatpak_status="✓ Available"
  fi
  if command -v fwupdmgr >/dev/null 2>&1; then
    fwupd_status="✓ Available"
  fi
  
  printf "║  • Snap:         %-57s ║\n" "$snap_status"
  printf "║  • Flatpak:      %-57s ║\n" "$flatpak_status"
  printf "║  • Firmware:     %-57s ║\n" "$fwupd_status"
  
  echo "║                                                                            ║"
  echo "╚════════════════════════════════════════════════════════════════════════════╝"
  echo ""
  
  # Exit after showing report
  exit 0
}

# Phase 3: Fallback to generic mode for unknown distributions
fallback_to_generic() {
  DETECTED_OS_FAMILY="generic"
  DETECTION_METHOD="fallback"
  
  echo "╔════════════════════════════════════════════════════════════════╗" >&2
  echo "║                    GENERIC FALLBACK MODE                       ║" >&2
  echo "╠════════════════════════════════════════════════════════════════╣" >&2
  echo "║                                                                ║" >&2
  echo "║  WARNING: Unknown or unsupported distribution detected.        ║" >&2
  echo "║                                                                ║" >&2
  echo "║  Operating in GENERIC mode with limited functionality:        ║" >&2
  echo "║    • Basic system operations only                              ║" >&2
  echo "║    • No distribution-specific optimizations                    ║" >&2
  echo "║    • Some features may not be available                        ║" >&2
  echo "║                                                                ║" >&2
  printf "║  Detected: %-51s ║\n" "${DETECTED_OS_ID:-unknown}" >&2
  echo "║                                                                ║" >&2
  echo "║  For full support, use: Ubuntu, Debian, Fedora, CentOS, RHEL, ║" >&2
  echo "║  Rocky, AlmaLinux, Arch, Manjaro, or openSUSE.                 ║" >&2
  echo "║                                                                ║" >&2
  echo "║  You can override detection with:                              ║" >&2
  echo "║    --distro <name>        (e.g., --distro ubuntu)              ║" >&2
  echo "║    --pkg-manager <pm>     (e.g., --pkg-manager apt)            ║" >&2
  echo "║                                                                ║" >&2
  echo "╚════════════════════════════════════════════════════════════════╝" >&2
  
  log "FALLBACK: Operating in generic mode for unknown distribution: ${DETECTED_OS_ID:-unknown}"
}

# Phase 3: Export detection variables for telemetry and logging
export_detection_vars() {
  # Called after detection is complete to make variables available
  export DETECTED_OS_ID
  export DETECTED_OS_NAME
  export DETECTED_OS_VERSION
  export DETECTED_OS_FAMILY
  export DETECTED_PKG_MANAGER
  export DETECTED_INIT_SYSTEM
  export DETECTION_METHOD
}
