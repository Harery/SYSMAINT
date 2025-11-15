#!/usr/bin/env bash
# Basic assertions for the Tier 1 profile launcher.

set -euo pipefail
cd "$(dirname "$0")/.."

SCRIPT=./sysmaint_profiles.sh

require_contains() {
  local output="$1" needle="$2" label="$3"
  if [[ "$output" != *"$needle"* ]]; then
    echo "[FAIL] $label — expected to find '$needle' in:\n$output" >&2
    exit 1
  fi
}

echo "[profiles] minimal preview"
minimal_cmd="$($SCRIPT --profile minimal --print-command)"
require_contains "$minimal_cmd" "--dry-run" "minimal includes --dry-run"
require_contains "$minimal_cmd" "--json-summary" "minimal includes --json-summary"

echo "[profiles] server hardened"
server_cmd="$($SCRIPT --profile server --print-command)"
require_contains "$server_cmd" "--security-audit" "server includes security audit"
require_contains "$server_cmd" "--check-zombies" "server includes zombie check"

echo "[profiles] extra flag passthrough"
extra_cmd="$($SCRIPT --profile desktop --print-command -- --color=never)"
require_contains "$extra_cmd" "--color=never" "extra flags appended"

echo "Tier 1 profile tests passed"
