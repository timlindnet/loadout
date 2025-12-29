#!/usr/bin/env bash
set -euo pipefail

ROOT="${OS_UBUNTU_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/common.sh
source "$ROOT/lib/common.sh"

ensure_ubuntu
log "Updating apt package lists..."
sudo_run apt-get update -y

