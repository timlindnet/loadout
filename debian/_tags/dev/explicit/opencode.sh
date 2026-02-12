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

if as_target bash -lc 'command -v opencode >/dev/null 2>&1 || [[ -x "$HOME/.opencode/bin/opencode" ]]'; then
  log "Opencode already installed for user $target_user."
  exit 0
fi

log "Installing Opencode for user: $target_user"
run_as_target bash -lc '
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "https://raw.githubusercontent.com/opencode-ai/opencode/refs/heads/main/install" | bash
elif command -v wget >/dev/null 2>&1; then
  wget -qO- "https://raw.githubusercontent.com/opencode-ai/opencode/refs/heads/main/install" | bash
else
  echo "Need curl or wget to install Opencode" >&2
  exit 1
fi
'
run_as_target bash -lc '
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
