# dotfiles

My personal Ubuntu setup, managed with Nix and standalone Home Manager.
One repo, one command, and a fresh machine ends up configured the same way every time.

Inspired by [kunchenguid/dotfiles](https://github.com/kunchenguid/dotfiles), which does the same on macOS with nix-darwin.
Ubuntu has no nix-darwin equivalent, so everything here is user-level Home Manager config, and system-level things (drivers, system services) stay with apt.

## What you get

Running the switch builds:

- GNOME settings (dark mode, auto-hiding dock, key repeat, tap to click, Nautilus list view)
- Blur my Shell extension, blurring the WezTerm window
- Nix user packages (ripgrep, fd, jq, lazygit, Neovim, Hack Nerd Font, herdr, Cursor agent)
- Shell (bash, aliases, ble.sh autosuggestions and syntax highlighting, starship prompt, fzf)
- Python tooling (uv)
- Editor (Neovim config with lazy.nvim and the rose-pine moon theme)
- Terminal (WezTerm config with the rose-pine moon theme)
- Agent configs (Claude Code and Cursor share one `AGENTS.md`)

## Prerequisites

- Ubuntu on x86_64 (tested on Ubuntu 24.04, GNOME 46).
- `sudo` access, for installing Nix and (on a desktop) the GPU driver link.

## Desktop and server profiles

The config comes in two profiles, and `rebuild.sh` picks one automatically:

- **desktop** (`common.nix` + `desktop.nix`) - used when GNOME is installed.
  Adds WezTerm, fonts, GNOME settings, Blur my Shell, and GPU drivers.
- **server** (`common.nix` only) - used everywhere else, like a machine you only reach over SSH.
  You get the same shell, CLI tools, Neovim, and agent configs; the look comes from your local terminal.

Force one with `DOTFILES_PROFILE=desktop ./rebuild.sh` or `DOTFILES_PROFILE=server ./rebuild.sh`.

Over SSH, Neovim copies to your local clipboard with OSC 52, which WezTerm supports.
Paste text copied elsewhere with your terminal's paste shortcut.

## Fresh-machine setup

```sh
git clone https://github.com/klbm9999/dotfiles.git
cd dotfiles
```

Before you run it, review "Make it yours" below.
`bootstrap.sh` applies the config to your machine, so do this first.

```sh
./bootstrap.sh
```

`bootstrap.sh` does six things, in order:

1. Installs `curl` and `git` with apt, if they're missing.
2. Installs Determinate Nix, if it isn't already installed.
3. Symlinks this repo to `~/.dotfiles`.
   This has to happen before the first switch, because the Home Manager modules point at config files through `~/.dotfiles`.
4. Checks the `user` configured in `flake.nix` against your actual username, and offers to fix it for you if they differ.
5. Runs the first switch through `rebuild.sh`, which picks the desktop or server profile and uses the Home Manager revision pinned in `flake.lock`.
   Existing files in the way (like Ubuntu's default `.bashrc` and `.profile`) are renamed to `*.backup`.
6. On a desktop, runs `non-nixos-gpu-setup` with sudo, so Nix GUI apps like WezTerm can use the GPU.

On a desktop, log out and back in afterwards, so GNOME picks up the new extensions and settings.
After that, `home-manager` exists and you're on the normal workflow below.

### Validate without applying

Once Nix is installed, you can check that the config builds without touching your home directory:

```sh
home-manager build --flake .#bhanu-desktop
home-manager build --flake .#bhanu-server
```

## Daily use

Edit the config files in place, then apply:

```sh
./rebuild.sh
```

To update packages, bump the lock file first:

```sh
nix flake update            # everything
nix flake update nixpkgs-unstable   # only Claude Code and Cursor agent
```

When a flake update brings a new Mesa build, the switch prints a `sudo ... non-nixos-gpu-setup` command.
Run it once to repoint the GPU drivers.

## Make it yours

This repo is mine.
If you clone it, review these before you run `bootstrap.sh`:

- **Username**: run `./bootstrap.sh` (it detects your username and offers to set it), or change the single `user = "bhanu"` line in `flake.nix`.
  The Home Manager config name, username, and home directory are all derived from that one variable.
  `rebuild.sh` reads the username from that same line, so nothing else needs changing.
- **GNOME extensions**: `desktop.nix` sets `enabled-extensions`, which replaces the whole list.
  Keep Ubuntu's defaults (`ding`, `ubuntu-dock`, `tiling-assistant`) in it, or they get disabled.
- **Conda**: `.bashrc` loads conda from `~/miniconda3` if it exists; Nix doesn't install it.

**Git identity:** this config does not set your git name or email.
Set them with `git config --global user.name` and `git config --global user.email`, or add a `programs.git` block to `common.nix`.

**Heads-up:**

- `home/AGENTS.md` is my personal agent policy, and `common.nix` installs it for Claude Code and Cursor.
  Edit or delete it if you don't want to inherit my instructions.
- `home/.claude/settings.json` is my Claude Code settings, including hooks and plugins.
- The `cc` alias is `claude --dangerously-skip-permissions`.
  Know what it does before you use it.

## Repo tour

- `flake.nix` - the entry point.
  Wires up nixpkgs (stable, plus unstable for fast-moving CLIs), Home Manager, and herdr, and declares the `<user>-desktop` and `<user>-server` Home Manager configs.
- `home-manager/common.nix` - config for every machine: CLI packages, shell, prompt, Neovim, agent configs, and the symlinks described below.
- `home-manager/desktop.nix` - desktop-only additions: WezTerm, fonts, GNOME settings, and extensions.
- `bootstrap.sh` - takes a fresh Ubuntu machine to an applied config.
  Run it once.
- `rebuild.sh` - re-applies the config after the first switch.
  Run it every time you make a change.
- `home/` - the actual config files that get symlinked into place.

## How the symlinks work

The files under `home/` are the real files.
Editing them here is editing your live config, with no rebuild needed to see the change.
The Home Manager modules use `mkOutOfStoreSymlink` to point paths like `~/.config/nvim` straight at `home/.config/nvim` in this repo, so the two never drift out of sync.
You only run `./rebuild.sh` when you change a `.nix` file, like a package list or a GNOME setting.

`~/.config/herdr` is linked as a whole directory, so herdr's runtime files (logs, sockets, sessions) land in `home/.config/herdr` too.
`.gitignore` ignores everything there except `config.toml`.

## Notes

The first time you launch `nvim`, it bootstraps [lazy.nvim](https://github.com/folke/lazy.nvim) by cloning plugins from GitHub.
That needs network access once; after that it's offline.

The first build compiles herdr from source, since it comes from its own flake without a binary cache, so expect it to take several minutes.

Nix installs user tools only.
Keep using apt for drivers, system services (docker, openssh-server), and anything else that has to live outside your home directory.

## License

This repo is licensed under MIT.
See `LICENSE`.
