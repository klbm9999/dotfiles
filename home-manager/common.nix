# Everything that works on any machine, including headless servers over SSH:
# shell, CLI tools, editor, and agent configs.
{ config, lib, pkgs, pkgs-unstable, user, herdr, treehouse, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  npmPrefix = config.home.sessionVariables.NPM_CONFIG_PREFIX;

  # axi CLIs, each installed from npm together with its same-named agent skill.
  axiTools = [ "tasks-axi" "gh-axi" "quota-axi" ];
  # Other global npm CLIs. acpx is the ACP bridge no-mistakes needs to run Cursor.
  npmTools = axiTools ++ [ "acpx" ];
in

{
  home.username = user;
  home.homeDirectory = "/home/${user}";
  home.stateVersion = "26.05";
  programs.home-manager.enable = true;

  # Non-NixOS (Ubuntu) integration: locales, terminfo, and XDG paths for Nix apps.
  # GPU drivers are only needed for GUI apps, so desktop.nix turns them on.
  targets.genericLinux.enable = true;
  targets.genericLinux.gpu.enable = lib.mkDefault false;

  home.packages = with pkgs; [
    ripgrep # fast search
    fd      # fast find
    jq      # json on the command line
    lazygit
    neovim
    herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs-unstable.cursor-cli
    nodejs_24
    treehouse.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  programs.bash = {
    enable = true;
    enableCompletion = true;
    historySize = 50000;
    historyFileSize = 1000000;
    historyControl = ["ignoredups" "erasedups"];
    shellOptions = ["histappend" "checkwinsize" "globstar"];

    shellAliases = {
      ".." = "cd ..";
      ll = "ls -alF";
      la = "ls -A";
      l = "ls -CF";
      k = "kubectl";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      cc = "claude --dangerously-skip-permissions";
      agent = "cursor-agent";
    };

    initExtra = ''
      # conda (installed separately in ~/miniconda3, not managed by Nix)
      __conda_setup="$("$HOME/miniconda3/bin/conda" 'shell.bash' 'hook' 2> /dev/null)"
      if [ $? -eq 0 ]; then
          eval "$__conda_setup"
      elif [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
          . "$HOME/miniconda3/etc/profile.d/conda.sh"
      else
          export PATH="$HOME/miniconda3/bin:$PATH"
      fi
      unset __conda_setup

      # ble.sh: autosuggestions and syntax highlighting
      source ${pkgs.blesh}/share/blesh/ble.sh
      # Ctrl+F (or Right / End) accepts the grey suggestion - ble.sh's default

      eval "$(uv generate-shell-completion bash)"
    '';
  };

  programs.uv = {
    enable = true;
    settings = {
      python-preference = "managed";
    };
  };

  programs.claude-code = {
    enable = true;
    package = pkgs-unstable.claude-code;
  };

  home.sessionPath = ["$HOME/.local/bin" "$HOME/.npm-global/bin"];
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$python$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](green)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style)";
    };
  };
  programs.fzf.enable = true;
  home.sessionVariables = {
    EDITOR = "nvim";
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
    CLAUDE_CODE_AUTO_COMPACT_WINDOW=500000;
  };

  # Tools that live outside the Nix store, installed on switch only when missing.
  # Activation does not read sessionVariables, so the npm prefix is exported here too.
  # Update them with `npm update -g`, `npx skills update -g` and `no-mistakes update`.
  home.activation.npmTools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export NPM_CONFIG_PREFIX="${npmPrefix}"
    export PATH="$NPM_CONFIG_PREFIX/bin:${lib.makeBinPath [ pkgs.nodejs_24 pkgs.git ]}:$PATH"
    for t in ${lib.escapeShellArgs npmTools}; do
      [ -x "$NPM_CONFIG_PREFIX/bin/$t" ] || run npm install -g "$t" || echo "warning: npm install $t failed" >&2
    done
    for t in ${lib.escapeShellArgs axiTools}; do
      [ -e "$HOME/.agents/skills/$t" ] \
        || run npx -y skills add "kunchenguid/$t" -g -y -s "$t" -a claude-code cursor \
        || echo "warning: skill $t failed" >&2
    done
  '';

  # no-mistakes updates itself in place, so it stays outside the Nix store.
  home.activation.noMistakes = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${lib.makeBinPath [ pkgs.curl pkgs.gnutar pkgs.gzip pkgs.coreutils ]}:$PATH"
    [ -x "$HOME/.no-mistakes/bin/no-mistakes" ] \
      || run sh -c 'curl -fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh | sh' \
      || echo "warning: no-mistakes install failed" >&2
  '';

  # ble.sh: Enter runs any complete command, like plain bash, so text typed
  # quickly (agents, firstmate worker startup) never sticks in multi-line editing.
  # https://github.com/akinomyoga/ble.sh/issues/639
  home.file.".blerc".text = ''
    function blerc/emacs-load-hook {
      ble-bind -f 'C-m' 'accept-line syntax'
      ble-bind -f 'RET' 'accept-line syntax'
      return 0
    }
    blehook/eval-after-load keymap_emacs blerc/emacs-load-hook
  '';

  home.file.".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/herdr".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";
  home.file.".claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";
  home.file.".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".cursor/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
