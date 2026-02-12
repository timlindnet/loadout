target_user="${SUDO_USER:-$USER}"
target_home="$(getent passwd "$target_user" | cut -d: -f6)"
if [[ -z "$target_home" ]]; then
  die "Cannot resolve home directory for user: $target_user"
fi

agent_ver=""
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  if agent_ver="$(sudo -u "$target_user" env HOME="$target_home" bash -lc 'command -v agent >/dev/null 2>&1 && agent --version')"; then
    log "Cursor CLI already installed for user $target_user ($agent_ver)."
    exit 0
  fi
else
  if agent_ver="$(env HOME="$target_home" bash -lc 'command -v agent >/dev/null 2>&1 && agent --version')"; then
    log "Cursor CLI already installed for user $target_user ($agent_ver)."
    exit 0
  fi
fi

log "Installing Cursor CLI for user: $target_user"

install_cmd=$(
  cat <<'EOF'
set -euo pipefail

if command -v curl >/dev/null 2>&1; then
  curl -fsSL "https://cursor.com/install" | bash
elif command -v wget >/dev/null 2>&1; then
  wget -qO- "https://cursor.com/install" | bash
else
  echo "Need curl or wget to install Cursor CLI" >&2
  exit 1
fi
EOF
)

verify_cmd='
if command -v agent >/dev/null 2>&1; then
  agent --version
elif [[ -x "$HOME/.local/bin/agent" ]]; then
  "$HOME/.local/bin/agent" --version
else
  echo "agent not found after install" >&2
  exit 1
fi
'

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  run sudo -u "$target_user" env HOME="$target_home" bash -lc "$install_cmd"
  run sudo -u "$target_user" env HOME="$target_home" bash -lc "$verify_cmd"
else
  run env HOME="$target_home" bash -lc "$install_cmd"
  run env HOME="$target_home" bash -lc "$verify_cmd"
fi

log "Done (Cursor CLI)."
