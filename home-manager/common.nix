# Everything that works on any machine, including headless servers over SSH:
# shell, CLI tools, editor, and agent configs.
{ config, lib, pkgs, pkgs-unstable, user, herdr, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
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

  home.sessionPath = ["$HOME/.local/bin"];
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
  home.sessionVariables.EDITOR = "nvim";

  home.file.".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/herdr".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";
  home.file.".claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";
  home.file.".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".cursor/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
