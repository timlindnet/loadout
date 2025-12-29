log "Installing RuneScape 3 launcher (alias)..."

# `rs3` lives under the `games` tag, but it's easy to assume it's part of
# `gaming`. Delegate to the canonical script.

# shellcheck source=games/explicit/rs3.sh
source "$OS_UBUNTU_ROOT/games/explicit/rs3.sh"

