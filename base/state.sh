#!/usr/bin/env bash
set -euo pipefail

ROOT="${OS_UBUNTU_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/common.sh
source "$ROOT/lib/common.sh"
# shellcheck source=lib/state.sh
source "$ROOT/lib/state.sh"

log "Ensuring nested state repo exists at: ${OS_UBUNTU_STATE_DIR:-$ROOT/state}"
ensure_state_repo "${OS_UBUNTU_STATE_DIR:-$ROOT/state}"

