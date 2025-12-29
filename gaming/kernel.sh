#!/usr/bin/env bash
set -euo pipefail

ROOT="${OS_UBUNTU_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/common.sh
source "$ROOT/lib/common.sh"

ensure_ubuntu

if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  # Support Ubuntu 24.04+ only (24+). Keep it simple and predictable.
  if [[ "${VERSION_ID:-0}" < "24.04" ]]; then
    die "gaming/kernel.sh supports Ubuntu 24.04+ only (detected VERSION_ID=${VERSION_ID:-unknown})."
  fi
fi

if ! have_cmd lspci; then
  log "Installing pciutils (for GPU detection)..."
  sudo_run apt-get update -y
  sudo_run apt-get install -y pciutils
fi

gpu_line="$(lspci -nn | grep -Ei 'vga|3d|display' | head -n1 || true)"
log "GPU detected: ${gpu_line:-unknown}"

if echo "$gpu_line" | grep -qi 'nvidia'; then
  # KISS: this script exists only to handle NVIDIA's driver stack.
  # Ubuntu's default kernel/kernel meta packages are already handled by the installer/normal upgrades.
  log "NVIDIA GPU detected: installing Ubuntu-recommended NVIDIA driver (stable for this Ubuntu release)"
  sudo_run apt-get update -y
  sudo_run apt-get install -y ubuntu-drivers-common

  # ubuntu-drivers picks the recommended, supported driver for this hardware/Ubuntu combo.
  sudo_run ubuntu-drivers autoinstall

  log "NVIDIA driver install requested. A reboot is typically required."
else
  log "Non-NVIDIA GPU detected: nothing to do in kernel.sh."
fi

