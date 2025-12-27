#!/usr/bin/env bash
# lib/progress/profiling.sh - Host profiling and scaling factors
# sysmaint library

_collect_host_profile() {
  local cores ram_kb ram_mb rtt host_json rtt_ms ts profile_file
  cores=$(getconf _NPROCESSORS_ONLN 2>/dev/null || nproc 2>/dev/null || echo 1)
  ram_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)
  ram_mb=$((ram_kb/1024))
  # Simple RTT measurement (first successful ping) fallback to 999 if unavailable
  if command -v ping >/dev/null 2>&1; then
    rtt=$(ping -c1 -w2 archive.ubuntu.com 2>/dev/null | awk -F'/' '/rtt/ {print $5}')
  fi
  rtt_ms=${rtt:-999.0}
  ts=$(date --iso-8601=seconds)
  host_json=$(cat <<EOF
{
  "timestamp": "${ts}",
  "cpu_cores": ${cores},
  "ram_mb": ${ram_mb},
  "network_rtt_ms": ${rtt_ms}
}
EOF
)
  profile_file="$STATE_DIR/host_profile.json"
  printf '%s
' "$host_json" >"$profile_file" 2>/dev/null || true
  # Derive scaling factors (heuristic):
  # CPU: if cores >=8 -> 0.85, >=4 -> 0.9 else 1.0 (faster cores reduce estimate)
  if (( cores >= 8 )); then CPU_SCALE=0.85; elif (( cores >= 4 )); then CPU_SCALE=0.90; else CPU_SCALE=1.00; fi
  # RAM: if ram_mb < 2048 -> 1.10 (slower), <4096 -> 1.05 else 1.0
  if (( ram_mb < 2048 )); then RAM_SCALE=1.10; elif (( ram_mb < 4096 )); then RAM_SCALE=1.05; else RAM_SCALE=1.00; fi
  # Network: if rtt_ms > 200 -> 1.20, >100 ->1.10, >50 ->1.05 else 1.0
  rtt_int=$(printf '%.0f' "$rtt_ms" 2>/dev/null || echo 999)
  if (( rtt_int > 200 )); then NETWORK_SCALE=1.20; elif (( rtt_int > 100 )); then NETWORK_SCALE=1.10; elif (( rtt_int > 50 )); then NETWORK_SCALE=1.05; else NETWORK_SCALE=1.00; fi
}

