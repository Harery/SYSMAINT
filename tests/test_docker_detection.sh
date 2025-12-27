#!/bin/bash
# Test Phase 3 auto-detection across all supported platforms

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Platform configurations: distro:tag:expected_family:expected_pm:expected_init
# Note: Docker containers may show "unknown" for init system
# Alpine requires bash installation for sysmaint to run
PLATFORMS=(
  "ubuntu:24.04:debian:apt:unknown"
  "ubuntu:22.04:debian:apt:unknown"
  "debian:12:debian:apt:unknown"
  "fedora:40:redhat:dnf:unknown"
  "rockylinux:9:redhat:dnf:unknown"
  "almalinux:9:redhat:dnf:unknown"
  "archlinux:latest:arch:pacman:systemd"
  "opensuse/leap:15:suse:zypper:unknown"
)

PASSED=0
FAILED=0
TOTAL=${#PLATFORMS[@]}

echo "════════════════════════════════════════════════════════════════"
echo "  SYSMAINT v2.4.0 - Phase 3 Docker Detection Test Suite"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Testing auto-detection on ${TOTAL} platforms..."
echo ""

for platform_config in "${PLATFORMS[@]}"; do
  IFS=':' read -r distro tag expected_family expected_pm expected_init <<< "$platform_config"
  
  echo "──────────────────────────────────────────────────────────────"
  echo "Testing: ${distro}:${tag}"
  echo "Expected: Family=${expected_family}, PM=${expected_pm}, Init=${expected_init}"
  echo ""
  
  # Run detection in Docker container
  if docker run --rm -v "${PROJECT_ROOT}:/sysmaint:ro" "${distro}:${tag}" \
    /bin/bash -c "cd /sysmaint && ./sysmaint --detect" > /tmp/detect_output_${distro//\//_}_${tag}.txt 2>&1; then
    
    # Extract detected values from the formatted output (handle multiple spaces)
    detected_family=$(grep "• Family:" /tmp/detect_output_${distro//\//_}_${tag}.txt | sed 's/.*Family:[[:space:]]*\([^[:space:]]*\).*/\1/')
    detected_pm=$(grep "• Package Manager:" /tmp/detect_output_${distro//\//_}_${tag}.txt | sed 's/.*Package Manager:[[:space:]]*\([^[:space:]]*\).*/\1/')
    detected_init=$(grep "• Init System:" /tmp/detect_output_${distro//\//_}_${tag}.txt | sed 's/.*Init System:[[:space:]]*\([^[:space:]]*\).*/\1/')
    
    # Validate detection
    if [[ "$detected_family" == "$expected_family" ]] && \
       [[ "$detected_pm" == "$expected_pm" ]] && \
       [[ "$detected_init" == "$expected_init" ]]; then
      echo "✓ PASSED - Detection correct"
      echo "  Detected: Family=${detected_family}, PM=${detected_pm}, Init=${detected_init}"
      ((PASSED++))
    else
      echo "✗ FAILED - Detection mismatch"
      echo "  Expected: Family=${expected_family}, PM=${expected_pm}, Init=${expected_init}"
      echo "  Detected: Family=${detected_family}, PM=${detected_pm}, Init=${detected_init}"
      ((FAILED++))
    fi
  else
    echo "✗ FAILED - Command execution error"
    echo "  (Check /tmp/detect_output_${distro//\//_}_${tag}.txt for details)"
    ((FAILED++))
  fi
  
  echo ""
done

echo "════════════════════════════════════════════════════════════════"
echo "  Test Results Summary"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Total Platforms:  ${TOTAL}"
echo "Passed:           ${PASSED} ($(( PASSED * 100 / TOTAL ))%)"
echo "Failed:           ${FAILED}"
echo ""

if [[ $FAILED -eq 0 ]]; then
  echo "✓ All platforms detected correctly!"
  exit 0
else
  echo "✗ Some platforms failed detection"
  exit 1
fi
