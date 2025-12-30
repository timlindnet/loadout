#!/usr/bin/env bash
set -euo pipefail

# Debian-family helpers and OS checks.
#
# This layer is meant to work on Debian and Debian-based distributions.

ensure_os() {
  if [[ ! -f /etc/os-release ]]; then
    die "Cannot detect OS (missing /etc/os-release)."
  fi
  # shellcheck disable=SC1091
  . /etc/os-release

  local id="${ID:-}"
  local like="${ID_LIKE:-}"

  if [[ "$id" == "debian" || "$id" == "ubuntu" ]] || [[ " $like " == *" debian "* ]]; then
    return 0
  fi

  die "This installer currently supports Debian-family only (detected: ${id:-unknown})."
}

apt_recover_dpkg() {
  # In some environments dpkg can be left half-configured (e.g. interrupted upgrade),
  # which blocks any apt operation with:
  #   "E: dpkg was interrupted, you must manually run 'sudo dpkg --configure -a' ..."
  #
  # Running this proactively is safe when dpkg is healthy (it's effectively a no-op).
  log "Ensuring dpkg is configured (dpkg --configure -a)..."
  if ! sudo_run dpkg --configure -a; then
    die "dpkg is in a broken state. Try: sudo dpkg --configure -a && sudo apt-get -f install"
  fi
}

apt_update() {
  apt_recover_dpkg
  sudo_run apt-get update -y
}

apt_upgrade() {
  # Keep it noninteractive and conservative with config files:
  # - prefer default action where possible
  # - keep existing config if a prompt would occur
  export DEBIAN_FRONTEND=noninteractive
  apt_recover_dpkg
  sudo_run apt-get upgrade -y \
    -o Dpkg::Options::=--force-confdef \
    -o Dpkg::Options::=--force-confold
}

apt_is_installed() {
  # Usage: apt_is_installed <apt-package-name>
  local pkg="$1"
  dpkg -s "$pkg" >/dev/null 2>&1
}

apt_install() {
  local pkgs=("$@")
  if [[ ${#pkgs[@]} -eq 0 ]]; then
    return 0
  fi

  local missing=()
  local p
  for p in "${pkgs[@]}"; do
    if apt_is_installed "$p"; then
      :
    else
      missing+=("$p")
    fi
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    log "All requested apt packages already installed: ${pkgs[*]}"
    return 0
  fi

  log "Installing apt packages: ${missing[*]}"
  apt_update
  sudo_run env DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing[@]}"
}

snap_is_installed() {
  # Usage: snap_is_installed <snap-name>
  have_cmd snap || return 1
  snap list "$1" >/dev/null 2>&1
}

snap_install() {
  # Usage: snap_install <snap-name> [--classic]
  #
  # Installs snapd if needed, then installs a snap only if not already installed.
  local name="$1"
  shift || true

  if snap_is_installed "$name"; then
    log "Snap already installed: $name"
    return 0
  fi

  if ! have_cmd snap; then
    apt_install snapd
  fi

  log "Installing snap: $name"
  sudo_run snap install "$name" "$@"
}

flatpak_is_installed() {
  # Usage: flatpak_is_installed <app-id>
  have_cmd flatpak || return 1
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    flatpak info --system "$1" >/dev/null 2>&1
  else
    sudo_run flatpak info --system "$1" >/dev/null 2>&1
  fi
}

flatpak_install() {
  # Usage: flatpak_install <app-id> [remote]
  #
  # Ensures flatpak is installed, ensures flathub exists, then installs the app
  # only if not already installed.
  local app_id="$1"
  local remote="${2:-flathub}"

  if flatpak_is_installed "$app_id"; then
    log "Flatpak already installed: $app_id"
    return 0
  fi

  if ! have_cmd flatpak; then
    apt_install flatpak
  fi

  if [[ "$remote" == "flathub" ]]; then
    sudo_run flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1 || true
  fi

  log "Installing flatpak: $app_id (remote: $remote)"
  sudo_run flatpak install -y --noninteractive "$remote" "$app_id"
}

# Back-compat wrappers for existing scripts (older names).
os_recover_pkg_system() { apt_recover_dpkg; }
os_apt_update() { apt_update; }
os_apt_upgrade() { apt_upgrade; }
os_apt_is_installed() { apt_is_installed "$@"; }
os_apt_install() { apt_install "$@"; }
os_snap_is_installed() { snap_is_installed "$@"; }
os_snap_install() { snap_install "$@"; }
os_flatpak_is_installed() { flatpak_is_installed "$@"; }
os_flatpak_install() { flatpak_install "$@"; }

# Older compat names.
os_pkg_update() { apt_update; }
os_pkg_upgrade() { apt_upgrade; }
os_pkg_is_installed() { apt_is_installed "$@"; }
os_pkg_install() { apt_install "$@"; }

