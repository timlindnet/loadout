if have_cmd docker; then
  log "Docker already installed ($(docker --version 2>/dev/null || true))."
else
  log "Installing Docker (docker.io)..."
  sudo_run apt-get install -y docker.io
fi

# Ensure a compose command is available.
# Prefer v2 integrations that support `docker compose`, and only fall back
# to legacy `docker-compose` when no v2 package exists.
if have_cmd docker && docker compose version >/dev/null 2>&1; then
  log "Docker Compose already available via 'docker compose'."
else
  compose_pkg=""
  if apt-cache show docker-compose-plugin >/dev/null 2>&1; then
    compose_pkg="docker-compose-plugin"
  elif apt-cache show docker-compose-v2 >/dev/null 2>&1; then
    compose_pkg="docker-compose-v2"
  elif apt-cache show docker-compose >/dev/null 2>&1; then
    compose_pkg="docker-compose"
  fi

  if [[ -n "$compose_pkg" ]]; then
    sudo_run apt-get install -y "$compose_pkg"
    if [[ "$compose_pkg" == "docker-compose" ]]; then
      warn "Installed legacy docker-compose. Use 'docker-compose' if 'docker compose' is unavailable."
    fi
  else
    warn "Could not find any Docker Compose package (docker-compose-plugin, docker-compose-v2, docker-compose)."
  fi
fi

# Enable docker service when systemd is present.
if have_cmd systemctl; then
  sudo_run systemctl enable --now docker || true
fi

# Add the invoking user to the docker group so docker works without sudo.
target_user="${SUDO_USER:-$USER}"
if getent group docker >/dev/null 2>&1; then
  :
else
  sudo_run groupadd docker || true
fi
sudo_run usermod -aG docker "$target_user" || true

log "Done (Docker). Log out/in for docker group changes to apply."

