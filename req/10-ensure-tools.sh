#!/usr/bin/env bash
set -euo pipefail

ROOT="${OS_UBUNTU_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/common.sh
source "$ROOT/lib/common.sh"

ensure_ubuntu

need=()
for c in curl wget git ca-certificates; do
  if ! have_cmd "$c"; then
    need+=("$c")
  fi
done

if [[ ${#need[@]} -eq 0 ]]; then
  log "Bootstrap tools already installed."
  exit 0
fi

log "Installing bootstrap tools: ${need[*]}"
sudo_run apt-get update -y
sudo_run apt-get install -y "${need[@]}"

