log "Installing Jagex Launcher repo + launcher..."

# Avoid any interactive apt/debconf prompts.
export DEBIAN_FRONTEND=noninteractive

apt_recover_dpkg

# If a previous version of this repo added the legacy Jagex "trusty" apt repo,
# remove it to avoid future apt errors (and the libssl1.1 dependency issue).
if [[ -f /etc/apt/sources.list.d/runescape.list ]]; then
  log "Removing legacy Jagex apt repo (/etc/apt/sources.list.d/runescape.list)..."
  sudo_run rm -f /etc/apt/sources.list.d/runescape.list
fi

# Install using the upstream helper script.
fetch_url "https://raw.githubusercontent.com/nmlynch94/com.jagexlauncher.JagexLauncher/main/install-jagex-launcher-repo.sh" | bash

log "Done (Jagex Launcher)."

