#!/usr/bin/env bash
# Applies the Home Manager config. Extra arguments go to `home-manager switch`,
# e.g. `./rebuild.sh -b backup` to move files that are in the way.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# common.nix and desktop.nix point at config files through ~/.dotfiles.
if [ "$(readlink -f ~/.dotfiles 2>/dev/null)" != "$DIR" ]; then
  ln -sfn "$DIR" ~/.dotfiles
fi

# The user must match the single `user = "..."` line in flake.nix.
USER_NAME="$(sed -nE 's/^[[:space:]]*user = "([^"]+)";.*/\1/p' "$DIR/flake.nix" | head -n1)"

# desktop.nix is GNOME-specific, so use it only where GNOME is installed.
# Override with DOTFILES_PROFILE=desktop or DOTFILES_PROFILE=server.
if [ -z "${DOTFILES_PROFILE:-}" ]; then
  if command -v gnome-shell >/dev/null 2>&1; then
    DOTFILES_PROFILE=desktop
  else
    DOTFILES_PROFILE=server
  fi
fi
FLAKE="$DIR#$USER_NAME-$DOTFILES_PROFILE"
echo "==> Applying $FLAKE"

if command -v home-manager >/dev/null 2>&1; then
  exec home-manager switch --flake "$FLAKE" "$@"
else
  # First run on a fresh machine: use the home-manager revision pinned in flake.lock.
  exec nix run --inputs-from "$DIR" home-manager -- switch --flake "$FLAKE" "$@"
fi
