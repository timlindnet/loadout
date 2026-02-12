target_user="${SUDO_USER:-$USER}"
target_home="$(getent passwd "$target_user" | cut -d: -f6)"
if [[ -z "$target_home" ]]; then
  die "Cannot resolve home directory for user: $target_user"
fi

as_target() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    sudo -u "$target_user" env HOME="$target_home" "$@"
  else
    env HOME="$target_home" "$@"
  fi
}

run_as_target() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    run sudo -u "$target_user" env HOME="$target_home" "$@"
  else
    run env HOME="$target_home" "$@"
  fi
}

if as_target bash -lc 'command -v agent >/dev/null 2>&1'; then
  log "Cursor CLI already installed for user $target_user."
  as_target bash -lc 'agent --version || true'
  exit 0
fi

log "Installing Cursor CLI for user: $target_user"
run_as_target bash -lc '
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "https://cursor.com/install" | bash
elif command -v wget >/dev/null 2>&1; then
  wget -qO- "https://cursor.com/install" | bash
else
  echo "Need curl or wget to install Cursor CLI" >&2
  exit 1
fi
'
run_as_target bash -lc '
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
