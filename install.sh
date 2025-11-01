#!/bin/bash

set -euo pipefail

# Minimal curl-installable bootstrapper for Traffic-UI
# Usage:
#   bash <(curl -Ls https://raw.githubusercontent.com/ScriptCascade/traffic-ui-open-source/main/install.sh)

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    return 1
  fi
}

ensure_apt_tools() {
  if ! command -v apt >/dev/null 2>&1; then
    echo "This installer currently supports Debian/Ubuntu (apt) only." >&2
    exit 1
  fi

  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
      SUDO="sudo"
    else
      echo "Please run as root or install sudo." >&2
      exit 1
    fi
  else
    SUDO=""
  fi

  $SUDO apt update -y >/dev/null 2>&1 || true
  $SUDO apt install -y curl unzip >/dev/null 2>&1 || true
}

main() {
  ensure_apt_tools

  TMP_DIR="$(mktemp -d)"
  
  # Ensure cleanup on exit
  trap 'rm -rf "$TMP_DIR" || true' EXIT INT TERM
  
  BRANCH="${TRAFFIC_UI_BRANCH:-main}"
  REPO_ZIP_URL="https://github.com/ScriptCascade/traffic-ui-open-source/archive/refs/heads/${BRANCH}.zip"

  echo "Downloading Traffic-UI (${BRANCH})..."
  if ! curl -fsSL "$REPO_ZIP_URL" -o "$TMP_DIR/repo.zip"; then
    echo "Failed to download repository" >&2
    exit 1
  fi

  echo "Extracting..."
  if ! unzip -q "$TMP_DIR/repo.zip" -d "$TMP_DIR"; then
    echo "Failed to extract repository" >&2
    exit 1
  fi
  
  # Find the extracted directory (GitHub zips create a directory like repo-branch/)
  EXTRACT_DIR=$(find "$TMP_DIR" -maxdepth 1 -mindepth 1 -type d | head -n1)
  
  if [ -z "$EXTRACT_DIR" ] || [ ! -d "$EXTRACT_DIR" ]; then
    echo "Failed to find extracted directory" >&2
    exit 1
  fi
  
  cd "$EXTRACT_DIR"

  if [ ! -f install-traffic-ui.sh ]; then
    echo "install-traffic-ui.sh not found in repository root" >&2
    echo "Current directory: $(pwd)" >&2
    echo "Contents: $(ls -la)" >&2
    exit 1
  fi

  chmod +x install-traffic-ui.sh
  echo "Running Traffic-UI installer..."
  bash ./install-traffic-ui.sh

  echo "Done."
}

main "$@"
