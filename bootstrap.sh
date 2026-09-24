#!/usr/bin/env bash
# Takes a fresh Ubuntu machine from nothing to an applied Home Manager config.
# Run this once. After it finishes, use ./rebuild.sh for every later change.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

echo "==> Step 1: base packages from apt"
# The Nix installer needs curl, and flakes in a git repo need git.
missing=()
for cmd in curl git; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [ ${#missing[@]} -eq 0 ]; then
  echo "    curl and git already installed, skipping"
else
  sudo apt-get update
  sudo apt-get install -y "${missing[@]}"
fi

echo "==> Step 2: Determinate Nix"
if command -v nix >/dev/null 2>&1; then
  echo "    nix already installed, skipping"
else
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
  # Load nix into this shell; new terminals get it automatically.
  # The profile script reads unset variables, so relax -u while sourcing it.
  set +u
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  set -u
fi

echo "==> Step 3: symlink this repo to ~/.dotfiles"
# common.nix and desktop.nix resolve their mkOutOfStoreSymlink paths through ~/.dotfiles, so this
# has to exist before the first switch or those links will be broken.
if [ "$(readlink -f ~/.dotfiles 2>/dev/null)" = "$DIR" ]; then
  echo "    ~/.dotfiles already points here, skipping"
else
  ln -sfn "$DIR" ~/.dotfiles
fi

echo "==> Step 4: check the configured username"
REAL_USER="$(whoami)"
FLAKE_USER="$(sed -nE 's/^[[:space:]]*user = "([^"]+)";.*/\1/p' "$DIR/flake.nix" | head -n1)"
if [ -z "$FLAKE_USER" ]; then
  echo "    Could not find the single \"user = \" line in flake.nix."
  echo "    Edit flake.nix yourself before continuing."
  exit 1
elif [ "$FLAKE_USER" != "$REAL_USER" ]; then
  echo "    flake.nix is configured for user \"$FLAKE_USER\", but you are \"$REAL_USER\"."
  read -r -p "    Rewrite flake.nix's \"user = \" line to \"$REAL_USER\"? [y/N] " REPLY
  if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
    sed -i -E "s/^([[:space:]]*user = \")[^\"]+(\";.*)/\1${REAL_USER}\2/" "$DIR/flake.nix"
    echo "    Updated. Review the change with: git diff flake.nix"
  else
    echo "    Skipped. Edit the single \"user = \" line in flake.nix yourself before continuing."
    exit 1
  fi
else
  echo "    flake.nix already matches \"$REAL_USER\", nothing to do."
fi

echo "==> Step 5: first home-manager switch"
# rebuild.sh picks the desktop or server profile, and on this first run uses the
# home-manager revision pinned in flake.lock (home-manager isn't installed yet).
# -b backup renames files already in the way (Ubuntu's default .bashrc and
# .profile) to *.backup instead of failing.
"$DIR/rebuild.sh" -b backup

echo "==> Step 6: GPU drivers for Nix GUI apps (wezterm, desktop profile only)"
# desktop.nix enables targets.genericLinux.gpu, which installs this helper; it
# points /run/opengl-driver at the Nix Mesa build. It needs root and is safe to
# re-run. The server profile doesn't install it, so this step is skipped there.
GPU_SETUP="$HOME/.nix-profile/bin/non-nixos-gpu-setup"
if [ -x "$GPU_SETUP" ]; then
  sudo "$(readlink -f "$GPU_SETUP")"
else
  echo "    non-nixos-gpu-setup not installed (server profile), skipping"
fi

echo "==> Done. On a desktop, log out and back in so GNOME picks up new extensions and settings."
echo "    Use ./rebuild.sh for future changes."
