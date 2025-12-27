#!/usr/bin/env bash
# lib/progress/panel.sh - Adaptive progress panel UI
# sysmaint library

show_progress() {
  # args: duration mode message
  local duration=${1:-$PROGRESS_DURATION}
  local mode=${2:-$PROGRESS_MODE}
  local msg=${3:-}

  # Only show if stdout is a TTY and mode is not 'none'
  if [[ "$mode" == "none" || ! -t 1 ]]; then
    return 0
  fi

  if [[ -n "$msg" ]]; then
    printf '%s ' "$msg" >&2
  fi

  case "$mode" in
  dots)
    for ((i=0; i<duration; i++)); do
      printf '.' >&2
      sleep 1
    done
    printf '\n' >&2
    ;;
  countdown)
    for ((i=duration; i>0; i--)); do
      printf '%d.. ' "$i" >&2
      sleep 1
    done
    printf '\n' >&2
    ;;
  bar)
    # Simple textual progress bar: fills over the specified duration in 20 steps
    local steps=20
    local step_duration
    if (( duration < steps )); then
      steps=$duration
    fi
    if (( steps > 0 )); then
      step_duration=$(awk -v d="$duration" -v s="$steps" 'BEGIN {printf "%.3f", d/s}')
    else
      step_duration=0
    fi
    local i filled pct
    printf '\n' >&2
    for ((i=1; i<=steps; i++)); do
      filled=$(( (i * 100) / steps ))
      pct=$filled
      # Build bar string
      local bar_fill=$(( (i * 20) / steps ))
      local bar
      bar=$(printf '%*s' 20 '' | tr ' ' '#')
      local filled_part=${bar:0:bar_fill}
      local empty_part
      empty_part=$(printf '%*s' $((20-bar_fill)) '' | tr ' ' ' ')
      printf '\r[%s%s] %3d%% %s' "$filled_part" "$empty_part" "$pct" "$msg" >&2
      sleep "$step_duration"
    done
    printf '\r[%s] 100%% %s\n' "####################" "$msg" >&2
    ;;
  spinner)
    # Animated spinner for the specified duration (seconds)
    local frames='|/-\\'
    local end_time=$(( $(date +%s) + duration ))
    local idx=0 ch now
    printf '\n' >&2
    while true; do
      now=$(date +%s)
      if (( now >= end_time )); then
        break
      fi
      ch=${frames:idx:1}
      printf '\r[%c] %s' "$ch" "$msg" >&2
      sleep 0.1
      ((idx=(idx+1)%${#frames}))
    done
    printf '\r[✔] %s\n' "$msg" >&2
    ;;
  adaptive)
    # No-op here: the adaptive multi-line panel is managed separately as a long-lived background task.
    ;;
  *)
    # unknown mode: no-op
    ;;
  esac
}

_render_bar() {
  # args: pct width
  local pct=$1 width=$2 filled empty
  if (( width <= 0 )); then width=20; fi
  if (( pct < 0 )); then pct=0; fi
  if (( pct > 100 )); then pct=100; fi
  filled=$(( (pct*width)/100 ))
  empty=$(( width - filled ))
  printf '['
  printf '%*s' "$filled" '' | tr ' ' '#'
  printf '%*s' "$empty" '' | tr ' ' ' '
  printf '] %3d%%' "$pct"
}

start_status_panel() {
  # Only on TTY and when mode=adaptive
  if [[ "$PROGRESS_MODE" != "adaptive" || ! -t 1 ]]; then
    return 0
  fi

  load_phase_estimates
  _compute_included_phases
  STATUS_PANEL_ACTIVE=true

  # Background refresher
  (
    printf '\n\n\n' >&2 # reserve 3 lines
    while $STATUS_PANEL_ACTIVE; do
      read -r opct osec eta ppct psec n1 n2 < <(_progress_snapshot)
      # Move cursor up 3 lines, carriage return
  printf '\033[3F\r' >&2
  # Line 1: overall
  printf ' Overall ' >&2; _render_bar "$opct" "$PROGRESS_WIDTH" >&2; printf '  Elapsed: %s  ETA: %s          \n' "$(_fmt_hms "$osec")" "$(_fmt_hms "$eta")" >&2
  # Line 2: phase
      local pdisp="$CURRENT_PHASE"; [[ -z "$pdisp" ]] && pdisp="starting"
  printf ' Phase   ' >&2; _render_bar "$ppct" "$PROGRESS_PHASE_WIDTH" >&2; printf '  %-22s %s/%s          \n' "$pdisp" "$(_fmt_hms "$psec")" "$(_fmt_hms "$(printf '%.0f' "$(_est_for_phase "$CURRENT_PHASE")")")" >&2
      # Line 3: next
      local nextline="Next: $n1"; [[ -n "$n2" ]] && nextline+=", $n2"
      printf ' %s\033[K\n' "$nextline" >&2
      sleep "$PROGRESS_REFRESH"
    done
    # Clean up panel area when done
    printf '\033[3F\r\033[J' >&2
  ) &
  STATUS_PANEL_PID=$!
}

update_status_panel_phase() {
  # args: phase_name
  local p="$1"
  CURRENT_PHASE="$p"
  CURRENT_PHASE_START_TS=$(date +%s)
}

stop_status_panel() {
  if [[ -n "$STATUS_PANEL_PID" ]]; then
    STATUS_PANEL_ACTIVE=false
    # Give the loop a moment to exit gracefully
    sleep "$PROGRESS_REFRESH"
    kill "$STATUS_PANEL_PID" >/dev/null 2>&1 || true
    wait "$STATUS_PANEL_PID" 2>/dev/null || true
    STATUS_PANEL_PID=""
  fi
}
