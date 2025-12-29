#!/usr/bin/env bash
set -euo pipefail

ROOT="${OS_UBUNTU_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/common.sh
source "$ROOT/lib/common.sh"

ensure_ubuntu

if ! have_cmd curl; then
  die "curl is required (run req/ scripts first)"
fi

target_user="${SUDO_USER:-$USER}"
target_home="$(getent passwd "$target_user" | cut -d: -f6)"
if [[ -z "$target_home" ]]; then
  die "Cannot resolve home directory for user: $target_user"
fi

log "Installing nvm + Node LTS for user: $target_user"

install_nvm_cmd=$(
  cat <<'EOF'
set -euo pipefail
export NVM_DIR="$HOME/.nvm"
mkdir -p "$NVM_DIR"
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi
# shellcheck disable=SC1091
source "$NVM_DIR/nvm.sh"
nvm install --lts
nvm alias default 'lts/*'
EOF
)

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  run sudo -u "$target_user" env HOME="$target_home" bash -lc "$install_nvm_cmd"
else
  run env HOME="$target_home" bash -lc "$install_nvm_cmd"
fi

log "Done (nvm + Node LTS)."

