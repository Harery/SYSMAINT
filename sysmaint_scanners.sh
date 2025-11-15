#!/usr/bin/env bash
# External Security Scanners Orchestrator
# Safely invoke optional tools (lynis, rkhunter) if present and capture JSON-ish summary.
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
OUT_DIR=${OUT_DIR:-"${SCRIPT_DIR}/scanner_artifacts"}
mkdir -p "$OUT_DIR"

TIMESTAMP=$(date -u +'%Y%m%dT%H%M%SZ')
SUMMARY_FILE="$OUT_DIR/summary_${TIMESTAMP}.json"
LYNIS_REPORT="$OUT_DIR/lynis_${TIMESTAMP}.log"
RKHUNTER_REPORT="$OUT_DIR/rkhunter_${TIMESTAMP}.log"

SCAN_LYNIS=${SCAN_LYNIS:-true}
SCAN_RKHUNTER=${SCAN_RKHUNTER:-true}

# Thresholds for failure
LYNIS_MIN_SCORE=${LYNIS_MIN_SCORE:-80}
RKHUNTER_MAX_WARNINGS=${RKHUNTER_MAX_WARNINGS:-5}
RKHUNTER_MAX_ROOTKITS=${RKHUNTER_MAX_ROOTKITS:-0}

# Artifact retention (days)
RETENTION_DAYS=${RETENTION_DAYS:-30}

echo "[scanners] Starting external scanners orchestration at $TIMESTAMP"
echo "[scanners] Thresholds: lynis_min=$LYNIS_MIN_SCORE rkhunter_max_warnings=$RKHUNTER_MAX_WARNINGS"

run_lynis() {
  command -v lynis >/dev/null 2>&1 || { echo "[scanners] lynis not installed, skipping"; return 0; }
  # Use audit system without modifications; suppress interactive pauses
  echo "[scanners] Running lynis audit --quick" >&2
  if lynis audit system --quick --no-colors --quiet >"$LYNIS_REPORT" 2>&1; then
    echo "[scanners] lynis completed" >&2
  else
    echo "[scanners] lynis failed (non-zero exit)" >&2
  fi
}

run_rkhunter() {
  command -v rkhunter >/dev/null 2>&1 || { echo "[scanners] rkhunter not installed, skipping"; return 0; }
  echo "[scanners] Running rkhunter --check --sk" >&2
  if rkhunter --check --sk --nocolors --logfile "$RKHUNTER_REPORT" >/dev/null 2>&1; then
    echo "[scanners] rkhunter completed" >&2
  else
    echo "[scanners] rkhunter encountered warnings/errors" >&2
  fi
}

LYNIS_SCORE=""; RKHUNTER_WARNINGS=""; RKHUNTER_ROOTKITS=""

if [[ "$SCAN_LYNIS" == "true" ]]; then
  run_lynis
  if [[ -s "$LYNIS_REPORT" ]]; then
    # Extract hardening index if present
    LYNIS_SCORE=$(grep -E "Hardening index" "$LYNIS_REPORT" | awk '{print $NF}' || true)
  fi
fi

if [[ "$SCAN_RKHUNTER" == "true" ]]; then
  run_rkhunter
  if [[ -s "$RKHUNTER_REPORT" ]]; then
    RKHUNTER_WARNINGS=$(grep -c "[Warning]" "$RKHUNTER_REPORT" || echo 0)
    RKHUNTER_ROOTKITS=$(grep -c "Rootkit" "$RKHUNTER_REPORT" || echo 0)
  fi
fi

cat >"$SUMMARY_FILE" <<JSON
{
  "timestamp": "$TIMESTAMP",
  "lynis_invoked": $( [[ "$SCAN_LYNIS" == "true" && -s "$LYNIS_REPORT" ]] && echo true || echo false ),
  "lynis_score": "${LYNIS_SCORE}",
  "rkhunter_invoked": $( [[ "$SCAN_RKHUNTER" == "true" && -s "$RKHUNTER_REPORT" ]] && echo true || echo false ),
  "rkhunter_warnings": "${RKHUNTER_WARNINGS}",
  "rkhunter_rootkit_refs": "${RKHUNTER_ROOTKITS}",
  "artifacts": {
    "lynis_report": "$( [[ -s "$LYNIS_REPORT" ]] && basename "$LYNIS_REPORT" || echo "")",
    "rkhunter_report": "$( [[ -s "$RKHUNTER_REPORT" ]] && basename "$RKHUNTER_REPORT" || echo "")"
  }
}
JSON

echo "[scanners] Summary written: $SUMMARY_FILE"

# Clean up old artifacts
if [[ -d "$OUT_DIR" ]]; then
  find "$OUT_DIR" -name "summary_*.json" -mtime +"$RETENTION_DAYS" -delete 2>/dev/null || true
  find "$OUT_DIR" -name "lynis_*.log" -mtime +"$RETENTION_DAYS" -delete 2>/dev/null || true
  find "$OUT_DIR" -name "rkhunter_*.log" -mtime +"$RETENTION_DAYS" -delete 2>/dev/null || true
  echo "[scanners] Cleaned artifacts older than $RETENTION_DAYS days"
fi

# Check thresholds and exit accordingly
FAILURES=0

if [[ -n "$LYNIS_SCORE" ]]; then
  # Extract numeric score (e.g., "75" from "75" or "[75]")
  SCORE_NUM=$(echo "$LYNIS_SCORE" | grep -oE '[0-9]+' | head -1 || echo "0")
  if (( SCORE_NUM > 0 && SCORE_NUM < LYNIS_MIN_SCORE )); then
    echo "[scanners] ❌ FAIL: Lynis score $SCORE_NUM below threshold $LYNIS_MIN_SCORE" >&2
    ((FAILURES++))
  else
    echo "[scanners] ✅ PASS: Lynis score $SCORE_NUM (threshold: $LYNIS_MIN_SCORE)"
  fi
fi

if [[ -n "$RKHUNTER_WARNINGS" && "$RKHUNTER_WARNINGS" != "0" ]]; then
  if (( RKHUNTER_WARNINGS > RKHUNTER_MAX_WARNINGS )); then
    echo "[scanners] ❌ FAIL: rkhunter warnings $RKHUNTER_WARNINGS exceed threshold $RKHUNTER_MAX_WARNINGS" >&2
    ((FAILURES++))
  else
    echo "[scanners] ⚠ WARNING: rkhunter warnings $RKHUNTER_WARNINGS (threshold: $RKHUNTER_MAX_WARNINGS)"
  fi
fi

if [[ -n "$RKHUNTER_ROOTKITS" && "$RKHUNTER_ROOTKITS" != "0" ]]; then
  if (( RKHUNTER_ROOTKITS > RKHUNTER_MAX_ROOTKITS )); then
    echo "[scanners] ❌ FAIL: rkhunter rootkit refs $RKHUNTER_ROOTKITS exceed threshold $RKHUNTER_MAX_ROOTKITS" >&2
    ((FAILURES++))
  fi
fi

if (( FAILURES > 0 )); then
  echo "[scanners] Done with $FAILURES failure(s)"
  exit 1
fi

echo "[scanners] Done - all thresholds passed"
exit 0
