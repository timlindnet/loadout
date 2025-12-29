log "Installing RuneScape launcher (snap)..."

# Avoid any interactive apt/debconf prompts.
export DEBIAN_FRONTEND=noninteractive

# `runescape-launcher` from the legacy Jagex apt repo depends on libssl1.1, which
# isn't available on Ubuntu 24+ (noble). Prefer snap for a stable install path.
apt_recover_dpkg

if [[ -f /etc/apt/sources.list.d/runescape.list ]]; then
  log "Removing legacy Jagex apt repo (/etc/apt/sources.list.d/runescape.list)..."
  sudo_run rm -f /etc/apt/sources.list.d/runescape.list
fi

if ! have_cmd snap; then
  sudo_run apt-get update -y
  sudo_run apt-get install -y snapd

  # On a normal Ubuntu desktop this should succeed. If systemd isn't available
  # (e.g. certain containers/WSL), snap installs may not work.
  if have_cmd systemctl; then
    sudo_run systemctl enable --now snapd.socket >/dev/null 2>&1 || true
    sudo_run systemctl enable --now snapd.service >/dev/null 2>&1 || true
  fi
fi

# Snap name varies by publisher/channel; try the common one first.
if ! sudo_run snap install runescape; then
  sudo_run snap install runescape-launcher
fi

log "Done (RuneScape launcher via snap)."

