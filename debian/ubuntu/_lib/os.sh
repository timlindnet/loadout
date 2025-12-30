#!/usr/bin/env bash
set -euo pipefail

# Ubuntu-specific checks / overrides (layered on top of debian/_lib/os.sh).

ensure_os() {
  if [[ ! -f /etc/os-release ]]; then
    die "Cannot detect OS (missing /etc/os-release)."
  fi
  # shellcheck disable=SC1091
  . /etc/os-release
  if [[ "${ID:-}" != "ubuntu" ]]; then
    die "Ubuntu layer selected but OS is not Ubuntu (detected: ${ID:-unknown})."
  fi
}

# Back-compat alias.
ensure_ubuntu() { ensure_os; }

