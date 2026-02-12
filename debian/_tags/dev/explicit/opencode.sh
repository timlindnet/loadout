target_user="$(loadout_target_user)"
target_home="$(loadout_target_home "$target_user")"

if as_target_user "$target_user" "$target_home" bash -lc 'command -v opencode >/dev/null 2>&1 || [[ -x "$HOME/.opencode/bin/opencode" ]]'; then
  log "Opencode already installed for user $target_user."
  exit 0
fi

log "Installing Opencode for user: $target_user"
fetch_url "https://raw.githubusercontent.com/opencode-ai/opencode/refs/heads/main/install" | run_as_target_user "$target_user" "$target_home" bash
run_as_target_user "$target_user" "$target_home" bash -lc '
if command -v opencode >/dev/null 2>&1; then
  command -v opencode
elif [[ -x "$HOME/.opencode/bin/opencode" ]]; then
  printf "%s\n" "$HOME/.opencode/bin/opencode"
else
  echo "opencode not found after install" >&2
  exit 1
fi
'

log "Done (Opencode)."
