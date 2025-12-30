#!/usr/bin/env bash
set -euo pipefail

# OS detection helpers (cross-distro).
#
# Source of truth: /etc/os-release
# - https://www.freedesktop.org/software/systemd/man/os-release.html

loadout_read_os_release() {
  local path="${LOADOUT_OS_RELEASE_PATH:-/etc/os-release}"
  [[ -f "$path" ]] || die "Cannot detect OS (missing $path)."

  # shellcheck disable=SC1090
  . "$path"

  LOADOUT_OS_ID="${ID:-}"
  LOADOUT_OS_ID_LIKE="${ID_LIKE:-}"
  LOADOUT_OS_VERSION_ID="${VERSION_ID:-}"
  LOADOUT_OS_VERSION_CODENAME="${VERSION_CODENAME:-}"

  [[ -n "$LOADOUT_OS_ID" ]] || die "Could not read OS ID from $path"
}

loadout_id_like_contains() {
  # Usage: loadout_id_like_contains <token>
  local token="$1"
  [[ " ${LOADOUT_OS_ID_LIKE:-} " == *" ${token} "* ]]
}

loadout_detect_family() {
  # Sets: LOADOUT_OS_FAMILY
  # Values: debian|fedora|arch|unknown
  #
  # Note: ID_LIKE is advisory; some distros omit it.
  local id="${LOADOUT_OS_ID:-}"

  if [[ "$id" == "ubuntu" || "$id" == "debian" ]] || loadout_id_like_contains debian; then
    LOADOUT_OS_FAMILY="debian"
    return 0
  fi

  if [[ "$id" == "fedora" ]] || loadout_id_like_contains fedora || loadout_id_like_contains rhel; then
    LOADOUT_OS_FAMILY="fedora"
    return 0
  fi

  if [[ "$id" == "arch" ]] || loadout_id_like_contains arch; then
    LOADOUT_OS_FAMILY="arch"
    return 0
  fi

  LOADOUT_OS_FAMILY="unknown"
  return 0
}

loadout_build_layer_chain() {
  # Usage: loadout_build_layer_chain <repo-root>
  #
  # Output (global): LOADOUT_LAYER_ROOTS_ARR=()
  #
  # Preferred layout example:
  # - debian/
  # - debian/ubuntu/
  # - debian/ubuntu/24.04/
  local repo_root="$1"

  LOADOUT_LAYER_ROOTS_ARR=()

  local family="${LOADOUT_OS_FAMILY:-unknown}"
  case "$family" in
    debian)
      if [[ -d "$repo_root/debian" ]]; then
        LOADOUT_LAYER_ROOTS_ARR+=("$repo_root/debian")
      fi

      # Distro-specific layer (e.g. debian/ubuntu/)
      if [[ -d "$repo_root/debian/${LOADOUT_OS_ID}" ]]; then
        LOADOUT_LAYER_ROOTS_ARR+=("$repo_root/debian/${LOADOUT_OS_ID}")
      fi

      # Version-specific layer (e.g. debian/ubuntu/24.04/)
      if [[ -n "${LOADOUT_OS_VERSION_ID:-}" && -d "$repo_root/debian/${LOADOUT_OS_ID}/${LOADOUT_OS_VERSION_ID}" ]]; then
        LOADOUT_LAYER_ROOTS_ARR+=("$repo_root/debian/${LOADOUT_OS_ID}/${LOADOUT_OS_VERSION_ID}")
      fi

      ;;
    fedora)
      if [[ -d "$repo_root/fedora" ]]; then
        LOADOUT_LAYER_ROOTS_ARR+=("$repo_root/fedora")
      fi
      if [[ -d "$repo_root/fedora/${LOADOUT_OS_ID}" ]]; then
        LOADOUT_LAYER_ROOTS_ARR+=("$repo_root/fedora/${LOADOUT_OS_ID}")
      fi
      if [[ -n "${LOADOUT_OS_VERSION_ID:-}" && -d "$repo_root/fedora/${LOADOUT_OS_ID}/${LOADOUT_OS_VERSION_ID}" ]]; then
        LOADOUT_LAYER_ROOTS_ARR+=("$repo_root/fedora/${LOADOUT_OS_ID}/${LOADOUT_OS_VERSION_ID}")
      fi
      ;;
    arch)
      if [[ -d "$repo_root/arch" ]]; then
        LOADOUT_LAYER_ROOTS_ARR+=("$repo_root/arch")
      fi
      if [[ -d "$repo_root/arch/${LOADOUT_OS_ID}" ]]; then
        LOADOUT_LAYER_ROOTS_ARR+=("$repo_root/arch/${LOADOUT_OS_ID}")
      fi
      ;;
    *)
      ;;
  esac

  if [[ ${#LOADOUT_LAYER_ROOTS_ARR[@]} -eq 0 ]]; then
    die "No supported layer roots found for: id=${LOADOUT_OS_ID} family=${LOADOUT_OS_FAMILY} version=${LOADOUT_OS_VERSION_ID:-unknown}"
  fi
}

