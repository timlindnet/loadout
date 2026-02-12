target_user="$(loadout_target_user)"
target_home="$(loadout_target_home "$target_user")"

# Precheck: if Node is already installed for the target user, stop immediately.
node_ver="$(as_target_user "$target_user" "$target_home" bash -lc 'command -v node >/dev/null 2>&1 && node -v' || true)"
if [[ -n "$node_ver" ]]; then
  log "Node is already installed for user $target_user ($node_ver)."
  exit 0
fi

log "Installing nvm + latest stable Node for user: $target_user"

run_as_target_user "$target_user" "$target_home" bash -lc 'mkdir -p "$HOME/.nvm"'

if ! as_target_user "$target_user" "$target_home" bash -lc '[[ -s "$HOME/.nvm/nvm.sh" ]]'; then
  fetch_url "https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh" | run_as_target_user "$target_user" "$target_home" bash
fi

run_as_target_user "$target_user" "$target_home" bash -lc '
set -euo pipefail
export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
source "$NVM_DIR/nvm.sh"
nvm install node
nvm alias default node >/dev/null
'

log "Done (nvm + Node)."

