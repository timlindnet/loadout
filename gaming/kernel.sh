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

# Ubuntu 24.04+ (supported): use the Ubuntu-supported stable kernel meta.
kernel_meta="linux-generic"
log "Ensuring kernel meta package: ${kernel_meta}"
sudo_run apt-get update -y
sudo_run apt-get install -y "$kernel_meta" linux-firmware

if echo "$gpu_line" | grep -qi 'nvidia'; then
  log "NVIDIA GPU detected: installing Ubuntu-recommended NVIDIA driver (stable, tested for this Ubuntu release)"
  sudo_run apt-get install -y ubuntu-drivers-common

  # ubuntu-drivers picks the recommended, supported driver for this hardware/Ubuntu combo.
  sudo_run ubuntu-drivers autoinstall

  log "NVIDIA driver install requested. A reboot is typically required."
else
  # AMD/Intel: no proprietary driver step. Kernel meta above is the main lever.
  if echo "$gpu_line" | grep -Eqi 'amd|advanced micro devices|ati'; then
    log "AMD GPU detected: using Ubuntu kernel + firmware (Mesa handled by gaming/mesa.sh)."
  elif echo "$gpu_line" | grep -qi 'intel'; then
    log "Intel GPU detected: using Ubuntu kernel + firmware (Mesa handled by gaming/mesa.sh)."
  else
    log "Unknown GPU vendor: installed kernel meta + firmware only."
  fi
fi

