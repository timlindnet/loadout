target_user="${SUDO_USER:-$USER}"
target_home="$(getent passwd "$target_user" | cut -d: -f6)"
if [[ -z "$target_home" ]]; then
  die "Cannot resolve home directory for user: $target_user"
fi

opencode_path=""
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  opencode_path="$(sudo -u "$target_user" env HOME="$target_home" bash -lc 'command -v opencode || true')"
else
  opencode_path="$(env HOME="$target_home" bash -lc 'command -v opencode || true')"
fi

if [[ -n "$opencode_path" ]]; then
  log "Opencode already installed for user $target_user ($opencode_path)."
  exit 0
fi

if [[ -x "$target_home/.opencode/bin/opencode" ]]; then
  log "Opencode already installed for user $target_user ($target_home/.opencode/bin/opencode)."
  exit 0
fi

log "Installing Opencode for user: $target_user"

install_cmd=$(
  cat <<'EOF'
set -euo pipefail

if command -v curl >/dev/null 2>&1; then
  curl -fsSL "https://raw.githubusercontent.com/opencode-ai/opencode/refs/heads/main/install" | bash
elif command -v wget >/dev/null 2>&1; then
  wget -qO- "https://raw.githubusercontent.com/opencode-ai/opencode/refs/heads/main/install" | bash
else
  echo "Need curl or wget to install Opencode" >&2
  exit 1
fi
EOF
)

verify_cmd='
if command -v opencode >/dev/null 2>&1; then
  command -v opencode
elif [[ -x "$HOME/.opencode/bin/opencode" ]]; then
  printf "%s\n" "$HOME/.opencode/bin/opencode"
else
  echo "opencode not found after install" >&2
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

log "Done (Opencode)."
