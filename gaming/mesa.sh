#!/usr/bin/env bash
set -euo pipefail

ROOT="${OS_UBUNTU_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/common.sh
source "$ROOT/lib/common.sh"

ensure_ubuntu

if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  if [[ "${VERSION_ID:-0}" < "24.04" ]]; then
    die "gaming/mesa.sh supports Ubuntu 24.04+ only (detected VERSION_ID=${VERSION_ID:-unknown})."
  fi
fi

if ! have_cmd lspci; then
  log "Installing pciutils (for GPU detection)..."
  sudo_run apt-get update -y
  sudo_run apt-get install -y pciutils
fi

gpu_line="$(lspci -nn | grep -Ei 'vga|3d|display' | head -n1 || true)"
log "GPU detected: ${gpu_line:-unknown}"

# KISS: avoid PPAs and just ensure Ubuntu-provided user-space Vulkan/Mesa bits.
# NVIDIA generally doesn't use Mesa for its main driver stack.
if echo "$gpu_line" | grep -qi 'nvidia'; then
  log "NVIDIA GPU detected: skipping Mesa install step."
  exit 0
fi

sudo_run apt-get update -y
sudo_run apt-get install -y \
  mesa-utils \
  vulkan-tools \
  mesa-vulkan-drivers \
  libgl1-mesa-dri

log "Mesa/Vulkan user-space packages installed (Ubuntu-provided)."

