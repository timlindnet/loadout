target_user="$(loadout_target_user)"
target_home="$(loadout_target_home "$target_user")"

if as_target_user "$target_user" "$target_home" bash -lc 'command -v agent >/dev/null 2>&1'; then
  log "Cursor CLI already installed for user $target_user."
  as_target_user "$target_user" "$target_home" bash -lc 'agent --version || true'
  exit 0
fi

log "Installing Cursor CLI for user: $target_user"
fetch_url "https://cursor.com/install" | run_as_target_user "$target_user" "$target_home" bash
run_as_target_user "$target_user" "$target_home" bash -lc '
if command -v agent >/dev/null 2>&1; then
  agent --version
elif [[ -x "$HOME/.local/bin/agent" ]]; then
  "$HOME/.local/bin/agent" --version
else
  echo "agent not found after install" >&2
  exit 1
fi
'

log "Done (Cursor CLI)."
