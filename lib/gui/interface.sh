#!/usr/bin/env bash
# lib/gui/interface.sh - Modern TUI/GUI interface for sysmaint v1.0.0
# sysmaint library
# Author: Mohamed Elharery <Mohamed@Harery.com>
# Copyright: 2025
#
# Modern Terminal User Interface (UI/UX 2026)
# Features: Animated elements, modern color gradients, smart navigation

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 COLOR THEME SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════

# Check terminal color support
setup_colors() {
  if [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]; then
    # Primary Colors
    export C_RESET=$'\033[0m'
    export C_BOLD=$'\033[1m'
    export C_DIM=$'\033[2m'
    export C_ITALIC=$'\033[3m'
    export C_UNDERLINE=$'\033[4m'
    export C_BLINK=$'\033[5m'
    export C_REVERSE=$'\033[7m'

    # UI/UX 2026 Modern Palette - Vibrant & Professional
    export C_PRIMARY=$'\033[38;5;33m'      # Deep Sky Blue - Trust & Technology
    export C_SECONDARY=$'\033[38;5;165m'   # Modern Magenta - Creative & Bold
    export C_ACCENT=$'\033[38;5;43m'      # Bright Turquoise - Innovation
    export C_SUCCESS=$'\033[38;5;71m'      # Vibrant Emerald - Growth
    export C_WARNING=$'\033[38;5;226m'     # Bright Amber - Attention
    export C_ERROR=$'\033[38;5;203m'       # Rose Red - Clear Error
    export C_INFO=$'\033[38;5;75m'        # Cyan Blue - Information

    # Gradient Blues - Modern Tech Feel
    export C_BLUE1=$'\033[38;5;20m'       # Darkest
    export C_BLUE2=$'\033[38;5;27m'
    export C_BLUE3=$'\033[38;5;33m'       # Mid
    export C_BLUE4=$'\033[38;5;39m'
    export C_BLUE5=$'\033[38;5;45m'       # Lightest

    # Gradient Purples - Premium Feel
    export C_PURPLE1=$'\033[38;5;90m'
    export C_PURPLE2=$'\033[38;5;126m'
    export C_PURPLE3=$'\033[38;5;165m'
    export C_PURPLE4=$'\033[38;5;213m'

    # Backgrounds - Subtle Professional
    export C_BG_DARK=$'\033[48;5;233m'
    export C_BG_DARKER=$'\033[48;5;235m'
    export C_BG_HIGHLIGHT=$'\033[48;5;237m'
    export C_BG_SELECTED=$'\033[48;5;26m'

    # Text Colors - High Contrast Readability
    export C_TEXT=$'\033[38;5;255m'       # Pure White
    export C_TEXT_DIM=$'\033[38;5;246m'    # Soft Gray
    export C_TEXT_BRIGHT=$'\033[38;5;231m' # Bright White

    # Special - Premium Accents
    export C_GOLD=$'\033[38;5;229m'       # Warm Gold - Premium
    export C_SILVER=$'\033[38;5;251m'     # Polished Silver - Elegance
    export C_BRONZE=$'\033[38;5;215m'     # Rich Bronze - Achievement
  else
    # Fallback - no colors
    export C_RESET="" C_BOLD="" C_DIM="" C_ITALIC="" C_UNDERLINE=""
    export C_PRIMARY="" C_SECONDARY="" C_ACCENT="" C_SUCCESS="" C_WARNING="" C_ERROR="" C_INFO=""
    export C_BLUE1="" C_BLUE2="" C_BLUE3="" C_BLUE4="" C_BLUE5=""
    export C_PURPLE1="" C_PURPLE2="" C_PURPLE3="" C_PURPLE4=""
    export C_BG_DARK="" C_BG_DARKER="" C_BG_HIGHLIGHT="" C_BG_SELECTED=""
    export C_TEXT="" C_TEXT_DIM="" C_TEXT_BRIGHT=""
    export C_GOLD="" C_SILVER="" C_BRONZE="" C_BLINK="" C_REVERSE=""
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 NON-INTERACTIVE DETECTION - CI/CD Support
# ═══════════════════════════════════════════════════════════════════════════════

# Detect if running in non-interactive mode (CI/CD, no TTY, or explicitly set)
_is_non_interactive() {
    # Check if explicitly set via environment variable
    if [[ "${NONINTERACTIVE:-false}" == "true" ]]; then
        return 0  # Is non-interactive
    fi

    # Check if CI environment is detected
    if [[ "${CI:-false}" == "true" ]]; then
        return 0  # Is non-interactive
    fi

    # Check if stdin is not a terminal (no TTY)
    if [[ ! -t 0 ]]; then
        return 0  # Is non-interactive
    fi

    return 1  # Is interactive
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎬 ANIMATION SYSTEM - Smooth Visual Feedback
# ═══════════════════════════════════════════════════════════════════════════════

# Animated gradient banner
show_animated_banner() {
  clear
  local banner=(
"${C_BLUE1}    ███████╗${C_BLUE2}██╗   ██╗${C_BLUE3}███████╗${C_BLUE4}███╗   ███╗${C_BLUE5} █████╗ ${C_PRIMARY}██╗███╗   ██╗████████╗${C_RESET}"
"${C_BLUE1}    ██╔════╝${C_BLUE2}╚██╗ ██╔╝${C_BLUE3}██╔════╝${C_BLUE4}████╗ ████║${C_BLUE5}██╔══██╗${C_PRIMARY}██║████╗  ██║╚══██╔══╝${C_RESET}"
"${C_BLUE1}    ███████╗${C_BLUE2} ╚████╔╝ ${C_BLUE3}███████╗${C_BLUE4}██╔████╔██║${C_BLUE5}███████║${C_PRIMARY}██║██╔██╗ ██║   ██║   ${C_RESET}"
"${C_BLUE1}    ╚════██║${C_BLUE2}  ╚██╔╝  ${C_BLUE3}╚════██║${C_BLUE4}██║╚██╔╝██║${C_BLUE5}██╔══██║${C_PRIMARY}██║██║╚██╗██║   ██║   ${C_RESET}"
"${C_BLUE1}    ███████║${C_BLUE2}   ██║   ${C_BLUE3}███████║${C_BLUE4}██║ ╚═╝ ██║${C_BLUE5}██║  ██║${C_PRIMARY}██║██║ ╚████║   ██║   ${C_RESET}"
"${C_BLUE1}    ╚══════╝${C_BLUE2}   ╚═╝   ${C_BLUE3}╚══════╝${C_BLUE4}╚═╝     ╚═╝${C_BLUE5}╚═╝  ╚═╝${C_PRIMARY}╚═╝╚═╝  ╚═══╝   ╚═╝   ${C_RESET}"
  )
  
  echo ""
  for line in "${banner[@]}"; do
    echo -e "$line"
    sleep 0.03
  done
  echo ""
  echo -e "${C_TEXT_DIM}    ══════════════════════════════════════════════════════════════════${C_RESET}"
  echo -e "${C_ACCENT}    ${C_BOLD}System Maintenance Orchestrator${C_RESET} ${C_TEXT_DIM}│${C_RESET} ${C_SECONDARY}v${SCRIPT_VERSION:-stable}${C_RESET} ${C_TEXT_DIM}│${C_RESET} ${C_INFO}Interactive Mode${C_RESET}"
  echo -e "${C_TEXT_DIM}    ══════════════════════════════════════════════════════════════════${C_RESET}"
  echo ""
}

# Loading spinner with text
show_spinner() {
  local text="${1:-Loading...}"
  local duration="${2:-2}"
  local spinners=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
  local end=$((SECONDS + duration))
  
  tput civis 2>/dev/null || true  # Hide cursor
  while [[ $SECONDS -lt $end ]]; do
    for spinner in "${spinners[@]}"; do
      printf "\r${C_PRIMARY}%s${C_RESET} ${C_TEXT}%s${C_RESET}" "$spinner" "$text"
      sleep 0.08
    done
  done
  printf "\r${C_SUCCESS}✓${C_RESET} ${C_TEXT}%s${C_RESET}\n" "$text"
  tput cnorm 2>/dev/null || true  # Show cursor
}

# Progress bar animation
show_progress_bar() {
  local current=$1
  local total=$2
  local width=${3:-40}
  local label="${4:-Progress}"
  
  local percent=$((current * 100 / total))
  local filled=$((current * width / total))
  local empty=$((width - filled))
  
  local bar=""
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty; i++)); do bar+="░"; done
  
  printf "\r  ${C_TEXT_DIM}%s${C_RESET} ${C_PRIMARY}[${C_ACCENT}%s${C_TEXT_DIM}%s${C_PRIMARY}]${C_RESET} ${C_BOLD}%3d%%${C_RESET}" \
         "$label" "${bar:0:$filled}" "${bar:$filled}" "$percent"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📦 CARD COMPONENT SYSTEM - Modern UI Cards
# ═══════════════════════════════════════════════════════════════════════════════

# Draw a modern card with title
draw_card() {
  local title="$1"
  local width="${2:-60}"
  local color="${3:-$C_PRIMARY}"
  
  local title_len=${#title}
  local padding=$(( (width - title_len - 4) / 2 ))
  local right_pad=$((width - padding - title_len - 2))
  
  echo -e "${color}╭$( printf '─%.0s' $(seq 1 $((width-2))) )╮${C_RESET}"
  echo -e "${color}│${C_RESET}$(printf ' %.0s' $(seq 1 $padding))${C_BOLD}${color}$title${C_RESET}$(printf ' %.0s' $(seq 1 $right_pad))${color}│${C_RESET}"
  echo -e "${color}├$( printf '─%.0s' $(seq 1 $((width-2))) )┤${C_RESET}"
}

# Close a card
close_card() {
  local width="${1:-60}"
  local color="${2:-$C_PRIMARY}"
  echo -e "${color}╰$( printf '─%.0s' $(seq 1 $((width-2))) )╯${C_RESET}"
}

# Card row with icon
card_row() {
  local icon="$1"
  local text="$2"
  local status="${3:-}"
  local width="${4:-60}"
  local color="${5:-$C_PRIMARY}"
  
  local content="  $icon  $text"
  local content_len=$((${#text} + 6))
  local status_len=${#status}
  local space=$((width - content_len - status_len - 4))
  [[ $space -lt 1 ]] && space=1
  
  if [[ -n "$status" ]]; then
    echo -e "${color}│${C_RESET}${content}$(printf ' %.0s' $(seq 1 $space))${status}  ${color}│${C_RESET}"
  else
    local right_space=$((width - content_len - 2))
    [[ $right_space -lt 1 ]] && right_space=1
    echo -e "${color}│${C_RESET}${content}$(printf ' %.0s' $(seq 1 $right_space))${color}│${C_RESET}"
  fi
}

# Separator line in card
card_separator() {
  local width="${1:-60}"
  local color="${2:-$C_PRIMARY}"
  echo -e "${color}├$( printf '─%.0s' $(seq 1 $((width-2))) )┤${C_RESET}"
}

# Empty row in card
card_empty() {
  local width="${1:-60}"
  local color="${2:-$C_PRIMARY}"
  echo -e "${color}│${C_RESET}$(printf ' %.0s' $(seq 1 $((width-2))))${color}│${C_RESET}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎮 INTERACTIVE MENU SYSTEM - Modern Selection Interface
# ═══════════════════════════════════════════════════════════════════════════════

# Check if dialog/whiptail available, fallback to pure bash
detect_gui_framework() {
  if command -v dialog >/dev/null 2>&1; then
    echo "dialog"
    return 0
  elif command -v whiptail >/dev/null 2>&1; then
    echo "whiptail"
    return 0
  else
    echo "pure"
    return 0
  fi
}

# Check GUI availability
check_gui_available() {
  return 0  # Pure bash fallback always works
}

# Modern pure-bash menu selector
pure_bash_menu() {
  local title="$1"
  shift
  local -a items=("$@")
  local selected=0
  local total=${#items[@]}
  
  # Hide cursor
  tput civis 2>/dev/null || true
  
  while true; do
    # Clear and redraw
    clear
    setup_colors
    show_animated_banner
    
    echo ""
    draw_card "$title" 68 "$C_PRIMARY"
    card_empty 68 "$C_PRIMARY"
    
    for i in "${!items[@]}"; do
      local item_text="${items[$i]}"
      local display_len=$((68 - 8))
      
      if [[ $i -eq $selected ]]; then
        printf "${C_PRIMARY}│${C_RESET}  ${C_BG_SELECTED}${C_BOLD} ▸ %-${display_len}s${C_RESET}${C_PRIMARY}│${C_RESET}\n" "$item_text"
      else
        printf "${C_PRIMARY}│${C_RESET}    ${C_TEXT}%-${display_len}s${C_RESET}${C_PRIMARY}│${C_RESET}\n" "$item_text"
      fi
    done
    
    card_empty 68 "$C_PRIMARY"
    echo -e "${C_PRIMARY}│${C_RESET}  ${C_ACCENT}↑↓${C_RESET} ${C_TEXT_DIM}Navigate${C_RESET}  ${C_TEXT_DIM}│${C_RESET}  ${C_ACCENT}Enter${C_RESET} ${C_TEXT_DIM}Select${C_RESET}  ${C_TEXT_DIM}│${C_RESET}  ${C_ACCENT}q${C_RESET} ${C_TEXT_DIM}Quit${C_RESET}                        ${C_PRIMARY}│${C_RESET}"
    close_card 68 "$C_PRIMARY"
    
    # Read single keypress
    if _is_non_interactive; then
        # In CI/non-interactive mode, don't wait for input
        key=""
    else
        if _is_non_interactive; then
        # In CI/non-interactive mode, don't wait for input
        key=""
    else
        read -rsn1 key
    fi
    fi
    
    # Handle escape sequences for arrow keys
    if [[ "$key" == $'\x1b' ]]; then
      read -rsn2 -t 0.1 key
      case "$key" in
        '[A') ((selected--)); [[ $selected -lt 0 ]] && selected=$((total - 1)) ;;
        '[B') ((selected++)); [[ $selected -ge $total ]] && selected=0 ;;
      esac
    else
      case "$key" in
        k) ((selected--)); [[ $selected -lt 0 ]] && selected=$((total - 1)) ;;
        j) ((selected++)); [[ $selected -ge $total ]] && selected=0 ;;
        "") # Enter
          tput cnorm 2>/dev/null || true
          echo $selected
          return 0
          ;;
        q|Q)
          tput cnorm 2>/dev/null || true
          return 1
          ;;
      esac
    fi
  done
}

# Modern checkbox selector
pure_bash_checklist() {
  local title="$1"
  shift
  local -a items=("$@")
  local selected=0
  local total=${#items[@]}
  local -a checked=()
  
  # Initialize all unchecked
  for ((i=0; i<total; i++)); do
    checked[i]=0
  done
  
  # Set defaults
  checked[0]=1  # Package Update
  checked[4]=1  # Orphan Purge
  checked[5]=1  # Clear /tmp
  checked[9]=1  # Check Zombies
  checked[10]=1 # Check Failed Services
  checked[12]=1 # Dry Run
  
  tput civis 2>/dev/null || true
  
  while true; do
    clear
    setup_colors
    show_animated_banner
    
    echo ""
    draw_card "$title" 72 "$C_PRIMARY"
    echo -e "${C_PRIMARY}│${C_RESET}  ${C_TEXT_DIM}Select operations to perform (recommended items pre-selected):${C_RESET}  ${C_PRIMARY}│${C_RESET}"
    card_separator 72 "$C_PRIMARY"
    
    for i in "${!items[@]}"; do
      local checkbox
      if [[ ${checked[$i]} -eq 1 ]]; then
        checkbox="${C_SUCCESS}◉${C_RESET}"
      else
        checkbox="${C_TEXT_DIM}○${C_RESET}"
      fi
      
      local item_text="${items[$i]}"
      local display_len=$((72 - 10))
      
      if [[ $i -eq $selected ]]; then
        printf "${C_PRIMARY}│${C_RESET} ${C_BG_SELECTED}${C_BOLD} $checkbox %-${display_len}s${C_RESET}${C_PRIMARY}│${C_RESET}\n" "$item_text"
      else
        printf "${C_PRIMARY}│${C_RESET}  $checkbox ${C_TEXT}%-${display_len}s${C_RESET}${C_PRIMARY}│${C_RESET}\n" "$item_text"
      fi
    done
    
    card_separator 72 "$C_PRIMARY"
    echo -e "${C_PRIMARY}│${C_RESET} ${C_ACCENT}↑↓${C_RESET}${C_TEXT_DIM}Move${C_RESET} ${C_TEXT_DIM}│${C_RESET} ${C_ACCENT}Space${C_RESET}${C_TEXT_DIM}Toggle${C_RESET} ${C_TEXT_DIM}│${C_RESET} ${C_ACCENT}Enter${C_RESET}${C_TEXT_DIM}Confirm${C_RESET} ${C_TEXT_DIM}│${C_RESET} ${C_ACCENT}a${C_RESET}${C_TEXT_DIM}All${C_RESET} ${C_TEXT_DIM}│${C_RESET} ${C_ACCENT}n${C_RESET}${C_TEXT_DIM}None${C_RESET} ${C_TEXT_DIM}│${C_RESET} ${C_ACCENT}q${C_RESET}${C_TEXT_DIM}Quit${C_RESET}    ${C_PRIMARY}│${C_RESET}"
    close_card 72 "$C_PRIMARY"
    
    if _is_non_interactive; then
        # In CI/non-interactive mode, don't wait for input
        key=""
    else
        read -rsn1 key
    fi
    
    if [[ "$key" == $'\x1b' ]]; then
      read -rsn2 -t 0.1 key
      case "$key" in
        '[A') ((selected--)); [[ $selected -lt 0 ]] && selected=$((total - 1)) ;;
        '[B') ((selected++)); [[ $selected -ge $total ]] && selected=0 ;;
      esac
    else
      case "$key" in
        k) ((selected--)); [[ $selected -lt 0 ]] && selected=$((total - 1)) ;;
        j) ((selected++)); [[ $selected -ge $total ]] && selected=0 ;;
        " ") # Space - toggle
          if [[ ${checked[selected]} -eq 1 ]]; then
            checked[selected]=0
          else
            checked[selected]=1
          fi
          ;;
        a|A) for ((i=0; i<total; i++)); do checked[i]=1; done ;;
        n|N) for ((i=0; i<total; i++)); do checked[i]=0; done ;;
        "") # Enter
          tput cnorm 2>/dev/null || true
          local result=""
          for i in "${!checked[@]}"; do
            [[ ${checked[$i]} -eq 1 ]] && result+="$i "
          done
          echo "$result"
          return 0
          ;;
        q|Q)
          tput cnorm 2>/dev/null || true
          return 1
          ;;
      esac
    fi
  done
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 MAIN GUI FLOW - Modern User Experience
# ═══════════════════════════════════════════════════════════════════════════════

# Build CLI arguments from selections
build_cli_args_from_selections() {
  local -n selections_ref=$1
  local -a args=()
  
  [[ "${selections_ref[upgrade]}" == "on" ]] && args+=("--upgrade")
  [[ "${selections_ref[security]}" == "on" ]] && args+=("--security-audit")
  [[ "${selections_ref[firmware]}" == "on" ]] && args+=("--fwupd")
  
  if [[ "${selections_ref[purge_kernels]}" == "on" ]]; then
    args+=("--purge-kernels")
    [[ -n "${selections_ref[keep_kernels]}" ]] && args+=("--keep-kernels=${selections_ref[keep_kernels]}")
  fi
  
  [[ "${selections_ref[clear_tmp]}" == "on" ]] && args+=("--clear-tmp")
  [[ "${selections_ref[orphan_purge]}" == "on" ]] && args+=("--orphan-purge")
  [[ "${selections_ref[browser_cache]}" == "on" ]] && args+=("--browser-cache-purge")
  [[ "${selections_ref[fstrim]}" == "on" ]] && args+=("--fstrim")
  [[ "${selections_ref[drop_caches]}" == "on" ]] && args+=("--drop-caches")
  [[ "${selections_ref[check_zombies]}" == "on" ]] && args+=("--check-zombies")
  [[ "${selections_ref[failed_services]}" == "on" ]] && args+=("--check-failed-services")
  [[ "${selections_ref[json_summary]}" == "on" ]] && args+=("--json-summary")
  [[ "${selections_ref[dry_run]}" == "on" ]] && args+=("--dry-run")
  
  [[ -n "${selections_ref[progress_mode]}" ]] && args+=("--progress=${selections_ref[progress_mode]}")
  [[ -n "${selections_ref[color_mode]}" ]] && args+=("--color=${selections_ref[color_mode]}")
  
  echo "${args[@]}"
}

# Show welcome screen
show_welcome_screen() {
  setup_colors
  show_animated_banner
  
  echo ""
  draw_card "Welcome to Interactive Mode" 68 "$C_ACCENT"
  card_empty 68 "$C_ACCENT"
  card_row "🎯" "Select maintenance operations visually" "" 68 "$C_ACCENT"
  card_row "⚡" "Configure advanced options with ease" "" 68 "$C_ACCENT"
  card_row "👁️" "Preview commands before execution" "" 68 "$C_ACCENT"
  card_row "✅" "Confirm each step for safety" "" 68 "$C_ACCENT"
  card_empty 68 "$C_ACCENT"
  card_separator 68 "$C_ACCENT"
  echo -e "${C_ACCENT}│${C_RESET}  ${C_TEXT_DIM}Navigation:${C_RESET} ${C_ACCENT}↑↓${C_RESET} ${C_TEXT_DIM}arrows${C_RESET}  ${C_ACCENT}Space${C_RESET} ${C_TEXT_DIM}toggle${C_RESET}  ${C_ACCENT}Enter${C_RESET} ${C_TEXT_DIM}select${C_RESET}  ${C_ACCENT}q${C_RESET} ${C_TEXT_DIM}quit${C_RESET}       ${C_ACCENT}│${C_RESET}"
  close_card 68 "$C_ACCENT"
  echo ""
  
  echo -e "  ${C_TEXT_DIM}Press any key to continue...${C_RESET}"
  if _is_non_interactive; then
    # In CI/non-interactive mode, skip waiting
    :
  else
    read -rsn1
  fi
}

# Profile selection with modern UI
show_profile_menu() {
  setup_colors
  
  local profiles=(
    "🟢 Minimal      │ Safe dry-run status check"
    "🔵 Standard     │ Recommended updates + cleanup"
    "🟣 Desktop      │ Full updates + desktop optimization"
    "🟠 Server       │ Security-focused maintenance"
    "🔴 Aggressive   │ All features enabled (caution)"
    "⚙️  Custom       │ Manual operation selection"
  )
  
  local choice
  choice=$(pure_bash_menu "Select Maintenance Profile" "${profiles[@]}")
  local exit_code=$?
  
  [[ $exit_code -ne 0 ]] && return 1
  
  case $choice in
    0) echo "--dry-run --json-summary --check-zombies" ;;
    1) echo "--orphan-purge --clear-tmp --json-summary" ;;
    2) echo "--upgrade --orphan-purge --clear-tmp --browser-cache-purge --fstrim --json-summary" ;;
    3) echo "--upgrade --security-audit --orphan-purge --clear-tmp --json-summary" ;;
    4) echo "--upgrade --purge-kernels --keep-kernels=2 --security-audit --orphan-purge --browser-cache-purge --fstrim --drop-caches --json-summary" ;;
    5) show_custom_selection ;;
  esac
}

# Custom operation selection
show_custom_selection() {
  local operations=(
    "📦 Package Update & Upgrade"
    "🔒 Security Audit"
    "🔧 Firmware Updates (fwupd)"
    "🗑️  Kernel Cleanup"
    "🧹 Orphaned Package Removal"
    "📁 Clear /tmp Directory"
    "🌐 Browser Cache Cleanup"
    "💾 Filesystem Trim (SSD)"
    "🔄 Drop Memory Caches"
    "⚠️  Check Zombie Processes"
    "❌ Check Failed Services"
    "📊 Generate JSON Summary"
    "👁️  Dry Run Mode (preview)"
  )
  
  local selected_indices
  selected_indices=$(pure_bash_checklist "Custom Operation Selection" "${operations[@]}")
  local exit_code=$?
  
  [[ $exit_code -ne 0 ]] && return 1
  
  declare -A selections=(
    [upgrade]="off" [security]="off" [firmware]="off" [purge_kernels]="off"
    [orphan_purge]="off" [clear_tmp]="off" [browser_cache]="off" [fstrim]="off"
    [drop_caches]="off" [check_zombies]="off" [failed_services]="off"
    [json_summary]="off" [dry_run]="off"
  )
  
  for idx in $selected_indices; do
    case $idx in
      0) selections[upgrade]="on" ;;
      1) selections[security]="on" ;;
      2) selections[firmware]="on" ;;
      3) selections[purge_kernels]="on" ;;
      4) selections[orphan_purge]="on" ;;
      5) selections[clear_tmp]="on" ;;
      6) selections[browser_cache]="on" ;;
      7) selections[fstrim]="on" ;;
      8) selections[drop_caches]="on" ;;
      9) selections[check_zombies]="on" ;;
      10) selections[failed_services]="on" ;;
      11) selections[json_summary]="on" ;;
      12) selections[dry_run]="on" ;;
    esac
  done
  
  show_progress_selection selections
  build_cli_args_from_selections selections
}

# Progress mode selection
# shellcheck disable=SC2034  # sel_ref is a nameref, modifications are visible to caller
show_progress_selection() {
  local -n sel_ref=$1
  
  local modes=(
    "⚪ None      │ Quiet mode, minimal output"
    "🔵 Dots      │ Simple dot progression"
    "🟢 Spinner   │ Rotating animation"
    "🟣 Bar       │ Progress bar display"
    "🟠 Adaptive  │ Intelligent mode selection"
  )
  
  local choice
  choice=$(pure_bash_menu "Select Progress Display Mode" "${modes[@]}")
  
  case $choice in
    0) sel_ref[progress_mode]="none" ;;
    1) sel_ref[progress_mode]="dots" ;;
    2) sel_ref[progress_mode]="spinner" ;;
    3) sel_ref[progress_mode]="bar" ;;
    4) sel_ref[progress_mode]="adaptive" ;;
  esac
}

# Confirmation screen with modern design
show_confirmation() {
  local cmd_args="$1"
  
  clear
  setup_colors
  show_animated_banner
  
  local cmd_len=${#cmd_args}
  local card_width=72
  
  echo ""
  draw_card "⚠️  Confirm Execution" $card_width "$C_WARNING"
  card_empty $card_width "$C_WARNING"
  echo -e "${C_WARNING}│${C_RESET}  ${C_TEXT}Command that will be executed:${C_RESET}$(printf ' %.0s' $(seq 1 35))${C_WARNING}│${C_RESET}"
  card_empty $card_width "$C_WARNING"
  
  # Handle long commands
  if [[ $cmd_len -lt 60 ]]; then
    printf "${C_WARNING}│${C_RESET}  ${C_BOLD}${C_ACCENT}sudo ./sysmaint %s${C_RESET}%*s${C_WARNING}│${C_RESET}\n" "$cmd_args" $((card_width - cmd_len - 22)) ""
  else
    echo -e "${C_WARNING}│${C_RESET}  ${C_BOLD}${C_ACCENT}sudo ./sysmaint${C_RESET}$(printf ' %.0s' $(seq 1 52))${C_WARNING}│${C_RESET}"
    printf "${C_WARNING}│${C_RESET}    ${C_ACCENT}%s${C_RESET}%*s${C_WARNING}│${C_RESET}\n" "$cmd_args" $((card_width - cmd_len - 6)) ""
  fi
  
  card_empty $card_width "$C_WARNING"
  card_separator $card_width "$C_WARNING"
  echo -e "${C_WARNING}│${C_RESET}  ${C_TEXT_DIM}Press${C_RESET} ${C_SUCCESS}${C_BOLD}y${C_RESET} ${C_TEXT_DIM}to execute  or${C_RESET}  ${C_ERROR}${C_BOLD}n${C_RESET} ${C_TEXT_DIM}to cancel${C_RESET}$(printf ' %.0s' $(seq 1 28))${C_WARNING}│${C_RESET}"
  close_card $card_width "$C_WARNING"
  echo ""
  
  echo -ne "  ${C_TEXT}Proceed? ${C_RESET}[${C_SUCCESS}y${C_RESET}/${C_ERROR}N${C_RESET}] "
  if _is_non_interactive; then
    # In CI/non-interactive mode, auto-accept
    confirm="y"
  else
    read -rsn1 confirm
  fi
  echo ""
  
  [[ "$confirm" =~ ^[Yy]$ ]] && return 0 || return 1
}

# Legacy dialog-based menu (fallback for compatibility)
# shellcheck disable=SC2034  # selections array is used via nameref in called functions
show_gui_menu() {
  local framework
  framework=$(detect_gui_framework)
  
  if [[ "$framework" == "pure" ]]; then
    show_custom_selection
    return $?
  fi
  
  local title="SYSMAINT v${SCRIPT_VERSION:-stable} - Interactive Mode"
  local height=25
  local width=80
  local list_height=18
  
  local items=(
    "1" "📦 Package Update & Upgrade (apt/dnf/pacman)" "ON"
    "2" "🔒 Security Audit (vulnerability scanning)" "OFF"
    "3" "🔧 Firmware Updates (fwupd)" "OFF"
    "4" "🗑️  Kernel Cleanup (purge old kernels)" "OFF"
    "5" "🧹 Orphaned Package Removal" "ON"
    "6" "📁 Clear /tmp Directory" "ON"
    "7" "🌐 Browser Cache Cleanup" "OFF"
    "8" "💾 Filesystem Trim (SSD optimization)" "OFF"
    "9" "🔄 Drop Memory Caches" "OFF"
    "10" "⚠️  Check Zombie Processes" "ON"
    "11" "❌ Check Failed Services" "ON"
    "12" "📊 Generate JSON Summary" "OFF"
    "13" "👁️  Dry Run Mode (preview only)" "ON"
  )
  
  local choices
  if [[ "$framework" == "dialog" ]]; then
    if ! choices=$(dialog --backtitle "SYSMAINT - System Maintenance" \
                     --title "$title" \
                     --checklist "\n ↑/↓ Navigate  │  SPACE Toggle  │  ENTER Confirm\n" \
                     "$height" "$width" "$list_height" \
                     "${items[@]}" \
                     3>&1 1>&2 2>&3); then
      return 1
    fi
  else
    if ! choices=$(whiptail --backtitle "SYSMAINT - System Maintenance" \
                       --title "$title" \
                       --checklist "\n ↑/↓ Navigate  │  SPACE Toggle  │  ENTER Confirm\n" \
                       "$height" "$width" "$list_height" \
                       "${items[@]}" \
                       3>&1 1>&2 2>&3); then
      return 1
    fi
  fi
  
  declare -A selections=( [upgrade]="off" [security]="off" [firmware]="off" [purge_kernels]="off" [orphan_purge]="off" [clear_tmp]="off" [browser_cache]="off" [fstrim]="off" [drop_caches]="off" [check_zombies]="off" [failed_services]="off" [json_summary]="off" [dry_run]="off" )
  
  for choice in $choices; do
    choice=$(echo "$choice" | tr -d '"')
    case $choice in
      1) selections[upgrade]="on" ;; 2) selections[security]="on" ;; 3) selections[firmware]="on" ;;
      4) selections[purge_kernels]="on" ;; 5) selections[orphan_purge]="on" ;; 6) selections[clear_tmp]="on" ;;
      7) selections[browser_cache]="on" ;; 8) selections[fstrim]="on" ;; 9) selections[drop_caches]="on" ;;
      10) selections[check_zombies]="on" ;; 11) selections[failed_services]="on" ;;
      12) selections[json_summary]="on" ;; 13) selections[dry_run]="on" ;;
    esac
  done
  
  show_advanced_options selections
  build_cli_args_from_selections selections
}

# Advanced options (for dialog mode compatibility)
# shellcheck disable=SC2034  # sel is a nameref, modifications are visible to caller
show_advanced_options() {
  local -n sel=$1
  local framework
  framework=$(detect_gui_framework)
  
  [[ "$framework" == "pure" ]] && return 0
  
  local progress_items=( "1" "⚪ None" "2" "🔵 Dots" "3" "🟢 Spinner" "4" "🟣 Bar" "5" "🟠 Adaptive" )
  
  local progress_choice
  if [[ "$framework" == "dialog" ]]; then
    progress_choice=$(dialog --backtitle "Advanced Options" --title "Progress Mode" --default-item "3" \
                             --menu "Select progress display:" 15 60 5 "${progress_items[@]}" 3>&1 1>&2 2>&3)
  else
    progress_choice=$(whiptail --backtitle "Advanced Options" --title "Progress Mode" --default-item "3" \
                               --menu "Select progress display:" 15 60 5 "${progress_items[@]}" 3>&1 1>&2 2>&3)
  fi
  
  case "$progress_choice" in
    1) sel[progress_mode]="none" ;; 2) sel[progress_mode]="dots" ;; 3) sel[progress_mode]="spinner" ;;
    4) sel[progress_mode]="bar" ;; 5) sel[progress_mode]="adaptive" ;;
  esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 MAIN ENTRY POINT
# ═══════════════════════════════════════════════════════════════════════════════

launch_gui_mode() {
  setup_colors
  
  # Show welcome
  show_welcome_screen
  
  # Get profile/custom selection
  local args
  args=$(show_profile_menu)
  
  if [[ -z "$args" ]]; then
    clear
    echo -e "\n${C_WARNING}⚠️  No operations selected${C_RESET}" >&2
    return 1
  fi
  
  # Show confirmation
  if show_confirmation "$args"; then
    clear
    echo "$args"
    return 0
  else
    clear
    echo -e "\n${C_ERROR}✗ Execution cancelled${C_RESET}" >&2
    return 1
  fi
}

# Export functions for main script
export -f detect_gui_framework
export -f check_gui_available
export -f show_gui_menu
export -f show_profile_menu
export -f show_advanced_options
export -f build_cli_args_from_selections
export -f launch_gui_mode
export -f setup_colors
export -f show_animated_banner
export -f show_spinner
export -f show_progress_bar
export -f draw_card
export -f close_card
export -f card_row
export -f card_separator
export -f card_empty
export -f pure_bash_menu
export -f pure_bash_checklist
export -f show_welcome_screen
export -f show_custom_selection
export -f show_progress_selection
export -f show_confirmation
