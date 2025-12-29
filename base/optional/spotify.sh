#!/usr/bin/env bash
set -euo pipefail

ROOT="${OS_UBUNTU_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=lib/common.sh
source "$ROOT/lib/common.sh"

ensure_ubuntu

log "Installing Spotify (snap)..."

sudo_run apt-get update -y
sudo_run apt-get install -y snapd
sudo_run snap install spotify

log "Done (Spotify)."

