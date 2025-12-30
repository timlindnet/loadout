log "Installing Steam (apt)..."

# Enable multiverse (Steam lives here on Ubuntu).
# Pre-scripts already run `apt-get update`, so we only update again after
# enabling multiverse.
if ! have_cmd add-apt-repository; then
  # add-apt-repository is provided by software-properties-common.
  os_pkg_install software-properties-common
fi

sudo_run add-apt-repository -y multiverse
os_pkg_update
os_pkg_install steam

log "Done (Steam)."

