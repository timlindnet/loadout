#!/usr/bin/env bash
set -euo pipefail

log() {
  # shellcheck disable=SC2059
  printf "[loadout] %s\n" "$*"
}

warn() {
  # shellcheck disable=SC2059
  printf "[loadout] WARN: %s\n" "$*" >&2
}

die() {
  warn "$*"
  exit 1
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

fetch_url() {
  # Usage: fetch_url <url>
  # Prints content to stdout.
  local url="$1"
  if have_cmd curl; then
    curl -fsSL "$url"
  elif have_cmd wget; then
    wget -qO- "$url"
  else
    die "Need curl or wget to fetch: $url"
  fi
}

require_cmd() {
  have_cmd "$1" || die "Missing required command: $1"
}

run() {
  log "+ $*"
  "$@"
}

sudo_run() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    run "$@"
  else
    run sudo "$@"
  fi
}

loadout_target_user() {
  # User we should install user-scoped tools for.
  printf "%s" "${SUDO_USER:-$USER}"
}

loadout_target_home() {
  # Usage: loadout_target_home [user]
  local user="${1:-$(loadout_target_user)}"
  local home
  home="$(getent passwd "$user" | cut -d: -f6)"
  [[ -n "$home" ]] || die "Cannot resolve home directory for user: $user"
  printf "%s" "$home"
}

as_target_user() {
  # Usage: as_target_user <user> <home> <cmd> [args...]
  local user="$1"
  local home="$2"
  shift 2
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    sudo -u "$user" env HOME="$home" "$@"
  else
    env HOME="$home" "$@"
  fi
}

run_as_target_user() {
  # Usage: run_as_target_user <user> <home> <cmd> [args...]
  local user="$1"
  local home="$2"
  shift 2
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    run sudo -u "$user" env HOME="$home" "$@"
  else
    run env HOME="$home" "$@"
  fi
}

