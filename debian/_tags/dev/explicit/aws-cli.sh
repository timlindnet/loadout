target_user="${SUDO_USER:-$USER}"
target_home="$(getent passwd "$target_user" | cut -d: -f6)"
if [[ -z "$target_home" ]]; then
  die "Cannot resolve home directory for user: $target_user"
fi

log "Installing AWS CLI (pip3 --user) for user: $target_user"

# AWS docs for CLI v1 on Linux recommend pip3 with --user, which installs to:
#   ~/.local/bin
sudo_run apt-get install -y python3-pip

install_cmd=$(
  cat <<'EOF'
set -euo pipefail
pip3 install awscli --upgrade --user
EOF
)

profile_cmd=$(
  cat <<'EOF'
set -euo pipefail

profile="$HOME/.profile"
marker="# Added by loadout (aws-cli)"

touch "$profile"

if ! grep -qF "$marker" "$profile"; then
  cat >>"$profile" <<'BLOCK'

# Added by loadout (aws-cli)
if [ -d "$HOME/.local/bin" ] ; then
  PATH="$HOME/.local/bin:$PATH"
fi
BLOCK
fi
EOF
)

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  run sudo -u "$target_user" env HOME="$target_home" bash -lc "$install_cmd"
  run sudo -u "$target_user" env HOME="$target_home" bash -lc "$profile_cmd"
else
  run env HOME="$target_home" bash -lc "$install_cmd"
  run env HOME="$target_home" bash -lc "$profile_cmd"
fi

# Verify (use ~/.local/bin regardless of current session profile state).
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  run sudo -u "$target_user" env HOME="$target_home" bash -lc 'export PATH="$HOME/.local/bin:$PATH"; aws --version'
else
  run env HOME="$target_home" bash -lc 'export PATH="$HOME/.local/bin:$PATH"; aws --version'
fi

log "Done (AWS CLI)."

