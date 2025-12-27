#!/usr/bin/env bash
# lib/json.sh — JSON generation and output functions for sysmaint
# sysmaint library
# License: MIT (see LICENSE file in repository root)
# Author: Mohamed Elharery <Mohamed@Harery.com>
# Copyright (c) 2025 Mohamed Elharery
#
# Provides: escape_json, array_to_json, write_json_summary

escape_json() {
  # Escape backslashes and double quotes, preserve newlines as \n
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e ':a;N;$!ba;s/\n/\\n/g'
}

# Helper: convert a bash array (name passed) into a JSON array string
array_to_json() {
  local -n _arr=$1
  local out='['
  local sep=''
  local v esc
  for v in "${_arr[@]}"; do
    esc=$(escape_json "$v")
    out+="$sep\"$esc\""
    sep=','
  done
  out+=']'
  printf '%s' "$out"
}

write_json_summary() {
  # Stub: JSON generation now handled in main script (sysmaint)
  # This function is preserved for backward compatibility but does nothing
  return 0
}
