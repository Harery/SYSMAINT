#!/usr/bin/env bash
# Build the Debian package in an isolated temp directory and verify its metadata.

set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v dpkg-buildpackage >/dev/null 2>&1; then
  echo "ERROR: dpkg-buildpackage is not installed" >&2
  exit 1
fi
if ! command -v dpkg-deb >/dev/null 2>&1; then
  echo "ERROR: dpkg-deb is not installed" >&2
  exit 1
fi

WORK_DIR="$TMP_DIR/sysmaint-pkg"
mkdir -p "$WORK_DIR"
rsync -a --delete --exclude '.git' --exclude '.github' --exclude '*.deb' --exclude 'build' "$ROOT_DIR/" "$WORK_DIR/"

LOG_FILE="$TMP_DIR/dpkg-build.log"

pushd "$WORK_DIR" >/dev/null
export DEB_BUILD_OPTIONS="${DEB_BUILD_OPTIONS:-nocheck}"
if ! dpkg-buildpackage -us -uc -b >"$LOG_FILE" 2>&1; then
  echo "Package build failed. Log:" >&2
  cat "$LOG_FILE" >&2
  exit 1
fi
popd >/dev/null

DEB_FILE=$(ls "$TMP_DIR"/*.deb 2>/dev/null | head -n1 || true)
if [[ -z "$DEB_FILE" ]]; then
  echo "ERROR: dpkg-buildpackage did not produce a .deb artifact" >&2
  cat "$LOG_FILE" >&2 || true
  exit 1
fi

if ! dpkg-deb --info "$DEB_FILE" >/dev/null; then
  echo "ERROR: dpkg-deb --info failed on $DEB_FILE" >&2
  exit 1
fi

if command -v lintian >/dev/null 2>&1; then
  lintian -i -I --pedantic "$DEB_FILE"
fi

echo "Package build succeeded: $DEB_FILE"
