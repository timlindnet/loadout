#!/usr/bin/env bash
set -euo pipefail

# Ubuntu-specific helpers and OS checks.

ensure_os() {
  if [[ ! -f /etc/os-release ]]; then
    die "Cannot detect OS (missing /etc/os-release)."
  fi
  # shellcheck disable=SC1091
  . /etc/os-release
  if [[ "${ID:-}" != "ubuntu" ]]; then
    die "This installer currently supports Ubuntu only (detected: ${ID:-unknown})."
  fi
}

os_recover_pkg_system() {
  # In some environments dpkg can be left half-configured (e.g. interrupted upgrade),
  # which blocks any apt operation with:
  #   "E: dpkg was interrupted, you must manually run 'sudo dpkg --configure -a' ..."
  #
  # Running this proactively is safe when dpkg is healthy (it's effectively a no-op).
  log "Ensuring dpkg is configured (dpkg --configure -a)..."

  # dpkg/apt can be temporarily busy (e.g. unattended upgrades). If so, wait with a
  # hard timeout and low-noise logging (never delete lock files).
  local timeout_s="${LOADOUT_DPKG_LOCK_TIMEOUT_S:-600}"
  local sleep_s=5
  local start_s=$SECONDS
  local last_status_s=$SECONDS
  local status_every_s=30
  local reported_busy="false"

  while true; do
    local out rc pid cmd etimes
    out=""
    rc=0

    if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
      out="$(dpkg --configure -a 2>&1)" || rc=$?
    else
      out="$(sudo dpkg --configure -a 2>&1)" || rc=$?
    fi

    if [[ "$rc" -eq 0 ]]; then
      return 0
    fi

    pid=""
    if [[ "$out" =~ pid[[:space:]]+([0-9]+) ]]; then
      pid="${BASH_REMATCH[1]}"
    fi

    # Common dpkg/apt lock messages.
    if [[ "$out" == *"lock-frontend"* ]] || [[ "$out" == *"dpkg frontend lock"* ]] || [[ "$out" == *"Unable to acquire the dpkg frontend lock"* ]] || [[ "$out" == *"Could not get lock /var/lib/dpkg/lock"* ]]; then
      if (( SECONDS - start_s >= timeout_s )); then
        warn "$out"
        die "Timed out waiting for dpkg/apt (${timeout_s}s). Another package process is still running. Wait for it to finish, then retry."
      fi

      if [[ "$reported_busy" != "true" ]]; then
        cmd=""
        etimes=""
        if [[ -n "$pid" ]]; then
          cmd="$(ps -p "$pid" -o comm= 2>/dev/null || true)"
          etimes="$(ps -p "$pid" -o etimes= 2>/dev/null | tr -d ' ' || true)"
        fi
        warn "dpkg/apt is busy${pid:+ (pid $pid${cmd:+: $cmd}${etimes:+, ${etimes}s elapsed})}; waiting for it to finish (timeout ${timeout_s}s)..."
        reported_busy="true"
        last_status_s=$SECONDS
      fi

      if (( SECONDS - last_status_s >= status_every_s )); then
        cmd=""
        etimes=""
        if [[ -n "$pid" ]]; then
          cmd="$(ps -p "$pid" -o comm= 2>/dev/null || true)"
          etimes="$(ps -p "$pid" -o etimes= 2>/dev/null | tr -d ' ' || true)"
        fi
        warn "dpkg/apt is busy${pid:+ (pid $pid${cmd:+: $cmd}${etimes:+, ${etimes}s elapsed})}; still waiting (timeout ${timeout_s}s)..."
        last_status_s=$SECONDS
      fi

      sleep "$sleep_s"
      # Slow down slightly to reduce churn/log spam on long waits.
      if (( sleep_s < 15 )); then
        sleep_s=$((sleep_s + 2))
      fi
      continue
    fi

    warn "$out"
    die "dpkg is in a broken state. Try: sudo dpkg --configure -a && sudo apt-get -f install"
  done
}

os_pkg_update() {
  os_recover_pkg_system
  local lock_timeout_s="${LOADOUT_APT_LOCK_TIMEOUT_S:-600}"
  sudo_run env DEBIAN_FRONTEND=noninteractive apt-get update -y \
    -o "DPkg::Lock::Timeout=${lock_timeout_s}" \
    -o "Acquire::Retries=3"
}

os_pkg_upgrade() {
  # Keep it noninteractive and conservative with config files:
  # - prefer default action where possible
  # - keep existing config if a prompt would occur
  os_recover_pkg_system
  local lock_timeout_s="${LOADOUT_APT_LOCK_TIMEOUT_S:-600}"
  sudo_run env DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
    -o "DPkg::Lock::Timeout=${lock_timeout_s}" \
    -o "Acquire::Retries=3" \
    -o Dpkg::Options::=--force-confdef \
    -o Dpkg::Options::=--force-confold
}

os_pkg_install() {
  local pkgs=("$@")
  if [[ ${#pkgs[@]} -eq 0 ]]; then
    return 0
  fi
  os_pkg_update
  local lock_timeout_s="${LOADOUT_APT_LOCK_TIMEOUT_S:-600}"
  sudo_run env DEBIAN_FRONTEND=noninteractive apt-get install -y \
    -o "DPkg::Lock::Timeout=${lock_timeout_s}" \
    -o "Acquire::Retries=3" \
    "${pkgs[@]}"
}

# Back-compat with existing Ubuntu scripts.
ensure_ubuntu() { ensure_os; }
apt_recover_dpkg() { os_recover_pkg_system; }

