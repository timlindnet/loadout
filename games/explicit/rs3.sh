log "Installing Jagex Launcher repo + launcher..."

# Avoid any interactive apt/debconf prompts.
export DEBIAN_FRONTEND=noninteractive

apt_recover_dpkg

if ! have_cmd flatpak; then
  log "Installing requirement: flatpak"
  sudo_run apt-get update -y
  sudo_run apt-get install -y flatpak
fi

# Install using the upstream helper script.
fetch_url "https://raw.githubusercontent.com/nmlynch94/com.jagexlauncher.JagexLauncher/main/install-jagex-launcher-repo.sh" | bash

log "Done (Jagex Launcher)."

