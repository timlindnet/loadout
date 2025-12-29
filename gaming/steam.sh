#!/usr/bin/env bash
set -euo pipefail

ROOT="${OS_UBUNTU_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/common.sh
source "$ROOT/lib/common.sh"

ensure_ubuntu

log "Installing Steam (apt)..."
sudo_run apt-get update -y

# Package name differs by Ubuntu release; try the common options.
if apt-cache show steam-installer >/dev/null 2>&1; then
  sudo_run apt-get install -y steam-installer
elif apt-cache show steam >/dev/null 2>&1; then
  sudo_run apt-get install -y steam
else
  die "No steam package found via apt-cache (enable multiverse?)"
fi

log "Done (Steam)."

