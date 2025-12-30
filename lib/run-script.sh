#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: run-script.sh <script-path>" >&2
  exit 2
fi

SCRIPT_PATH="$1"

# Resolve repo root from env or from script path.
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
REPO_ROOT="${LOADOUT_REPO_ROOT:-}"
if [[ -z "$REPO_ROOT" ]]; then
  # Best-effort: assume scripts live under <repo>/<layer>/...
  REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

# Shared helpers.
# shellcheck source=lib/common.sh
source "$REPO_ROOT/lib/common.sh"

# OS helpers (layered).
#
# When LOADOUT_LAYER_ROOTS is set (colon-separated list), source each layer's
# _lib/os.sh in order. Later layers may override functions from earlier layers.
if [[ -n "${LOADOUT_LAYER_ROOTS:-}" ]]; then
  IFS=':' read -r -a _layers <<<"${LOADOUT_LAYER_ROOTS}"
  loaded="false"
  for _layer in "${_layers[@]}"; do
    [[ -n "$_layer" ]] || continue
    if [[ -f "$_layer/_lib/os.sh" ]]; then
      # shellcheck disable=SC1090
      source "$_layer/_lib/os.sh"
      loaded="true"
    fi
  done
  if [[ "$loaded" != "true" ]]; then
    die "No _lib/os.sh found in any layer root (LOADOUT_LAYER_ROOTS=$LOADOUT_LAYER_ROOTS)"
  fi
else
  # Back-compat: prefer OS root set by the runner; otherwise resolve from script path.
  OS_ROOT="${LOADOUT_OS_ROOT:-${OS_UBUNTU_ROOT:-}}"
  if [[ -z "${OS_ROOT:-}" ]]; then
    case "$(basename "$SCRIPT_DIR")" in
      optional|explicit)
        OS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
        ;;
      *)
        OS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
        ;;
    esac
  fi
  # shellcheck disable=SC1090
  source "$OS_ROOT/_lib/os.sh"
fi

ensure_os

# Execute script body in this shell (scripts are snippets, not standalone executables).
# shellcheck disable=SC1090
source "$SCRIPT_PATH"

