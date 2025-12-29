#!/usr/bin/env bash
set -euo pipefail

ROOT="${OS_UBUNTU_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=lib/common.sh
source "$ROOT/lib/common.sh"

ensure_ubuntu

log "Installing Spotify (apt repo)..."

sudo_run apt-get update -y
sudo_run apt-get install -y gpg ca-certificates

keyring="/etc/apt/keyrings/spotify.gpg"
list="/etc/apt/sources.list.d/spotify.list"

sudo_run mkdir -p /etc/apt/keyrings

tmp="$(mktemp)"
trap 'rm -f "$tmp"' RETURN

fetch_url "https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg" >"$tmp"
sudo_run gpg --dearmor -o "$keyring" "$tmp"

printf "deb [signed-by=%s] http://repository.spotify.com stable non-free\n" "$keyring" | sudo_run tee "$list" >/dev/null

sudo_run apt-get update -y
sudo_run apt-get install -y spotify-client

log "Done (Spotify)."

