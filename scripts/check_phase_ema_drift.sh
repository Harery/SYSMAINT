#!/usr/bin/env bash
set -euo pipefail
BASELINE=${1:-phase_ema_baseline.json}
SUMMARY_DIR="${SUMMARY_DIR:-/tmp/system-maintenance}" 
THRESHOLD_PCT=${THRESHOLD_PCT:-30}

latest_json=$(ls -1t "$SUMMARY_DIR"/sysmaint_*.json 2>/dev/null | head -n1 || true)
if [[ -z "$latest_json" ]]; then
  echo "ERROR: no latest JSON summary found" >&2; exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq required" >&2; exit 1
fi
if [[ ! -f "$BASELINE" ]]; then
  echo "No baseline present; creating $BASELINE" >&2
  jq '.phase_estimates_ema' "$latest_json" > "$BASELINE"
  echo "Baseline created; exiting" >&2
  exit 0
fi

drift_flag=0
echo "Comparing EMA drift (threshold ${THRESHOLD_PCT}%):" >&2
for key in $(jq -r 'keys[]' "$BASELINE"); do
  old=$(jq -r --arg k "$key" '.[$k]' "$BASELINE")
  new=$(jq -r --arg k "$key" '.phase_estimates_ema[$k]' "$latest_json")
  [[ "$old" == "null" || -z "$new" || "$new" == "null" ]] && continue
  # numeric check
  if [[ "$old" =~ ^[0-9]+(\.[0-9]+)?$ && "$new" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    diff=$(awk -v o="$old" -v n="$new" 'BEGIN{ if(o==0){print 0}else{printf "%.2f", ((n-o)/o)*100}}')
    pct=${diff}
    abs=${pct#-}
    if awk -v a="$abs" -v t="$THRESHOLD_PCT" 'BEGIN{exit !(a>t)}'; then
      echo "❌ Drift: $key old=$old new=$new change=${pct}%" >&2
      drift_flag=1
    else
      echo "✅ $key stable (change=${pct}%)" >&2
    fi
  fi
done

if (( drift_flag == 1 )); then
  echo "FAIL: EMA drift exceeded threshold" >&2
  exit 1
fi
echo "All EMA metrics within threshold" >&2
exit 0