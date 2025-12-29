log "Installing Steam (apt)..."

# Ensure dpkg isn't left half-configured (blocks apt operations).
apt_recover_dpkg

# Steam is a 32-bit program and expects i386 multiarch enabled.
# If an Nvidia proprietary driver is present, Steam also needs 32-bit Nvidia libs.
added_i386_arch="no"
if ! dpkg --print-foreign-architectures | grep -qx "i386"; then
  log "Enabling i386 multiarch (required for Steam)..."
  sudo_run dpkg --add-architecture i386
  added_i386_arch="yes"
fi

# Only apt-get update if we changed architectures (keeps this fast/idempotent).
if [[ "$added_i386_arch" == "yes" ]]; then
  sudo_run apt-get update
fi

# Avoid Steam's interactive debconf prompt about missing 32-bit Nvidia driver libs.
# NOTE: On Ubuntu 24+, `nvidia-driver-libs:i386` is often not published; the 32-bit
# libs are provided by versioned packages like `libnvidia-gl-<version>:i386`.
if [[ -e /proc/driver/nvidia/version ]] || have_cmd nvidia-smi; then
  log "Nvidia driver detected; ensuring 32-bit Nvidia libs for Steam..."

  pkg_installable() {
    # True iff apt has an install candidate (not "Candidate: (none)").
    local pkg="$1"
    local cand=""
    cand="$(apt-cache policy "$pkg" 2>/dev/null | awk '/Candidate:/{print $2; exit}')"
    [[ -n "$cand" && "$cand" != "(none)" ]]
  }

  # Legacy (some Ubuntu releases): metapackage exists for i386.
  if pkg_installable "nvidia-driver-libs:i386"; then
    if ! dpkg -s nvidia-driver-libs:i386 >/dev/null 2>&1; then
      sudo_run apt-get install -y nvidia-driver-libs:i386
    fi
  else
    # Preferred (Ubuntu 24+): install matching versioned 32-bit GL libs if we can
    # detect the installed amd64 package name.
    gl_pkg="$(dpkg-query -W -f='${Package}\n' 'libnvidia-gl-[0-9]*' 2>/dev/null | sort -V | awk 'END{print}')"
    if [[ -n "${gl_pkg:-}" ]]; then
      if pkg_installable "${gl_pkg}:i386"; then
        if ! dpkg -s "${gl_pkg}:i386" >/dev/null 2>&1; then
          sudo_run apt-get install -y "${gl_pkg}:i386"
        fi
      else
        warn "Nvidia detected but ${gl_pkg}:i386 is not available via apt; skipping 32-bit Nvidia libs."
      fi
    else
      warn "Nvidia detected but no apt-managed libnvidia-gl-<version> package found; skipping 32-bit Nvidia libs."
    fi
  fi
fi

# Package name differs by Ubuntu release; try the common options.
if apt-cache show steam-installer >/dev/null 2>&1; then
  sudo_run apt-get install -y steam-installer
elif apt-cache show steam >/dev/null 2>&1; then
  sudo_run apt-get install -y steam
else
  die "No steam package found via apt-cache (enable multiverse?)"
fi

log "Done (Steam)."

