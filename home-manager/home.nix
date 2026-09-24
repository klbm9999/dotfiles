{ config, lib, pkgs, pkgs-unstable, user, herdr, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in

{
  # gnome settings
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Yaru-dark";
    };

    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-fixed = false;
      autohide = true;
      intellihide = true;
    };

    "org/gnome/desktop/peripherals/keyboard" = {
      repeat-interval = lib.hm.gvariant.mkUint32 30;
      delay = lib.hm.gvariant.mkUint32 250;
    };

    "org/gnome/desktop/peripherals/touchpad".tap-to-click = true;
    "org/gnome/nautilus/preferences".default-folder-viewer = "list-view";
    "org/gnome/shell/extensions/ding".show-home = false;

    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [
        # Ubuntu's defaults: this list replaces the current one, so keep these
        "ding@rastersoft.com"
        "ubuntu-dock@ubuntu.com"
        "tiling.assistant@ubuntu.com"
        "blur-my-shell@aunetx"
      ];
    };

    "org/gnome/shell/extensions/blur-my-shell/applications" = {
      blur = true;
      enable-all = false;                       # only the apps in the whitelist
      whitelist = ["org.wezfurlong.wezterm"];   
      opacity = 230;                            # window opacity, 0-255 (default 215)
      dynamic-opacity = false;                  # stay see-through when focused
      sigma = 30;                               # blur strength (default)
    };
  };

  home.username = user;
  home.homeDirectory = "/home/${user}";
  home.stateVersion = "26.05";
  programs.home-manager.enable = true;

  # Non-NixOS (Ubuntu) integration: app launchers, and GPU drivers for Nix GUI apps like wezterm.
  targets.genericLinux.enable = true;

  home.packages = with pkgs; [
    wezterm # default terminal
    ripgrep # fast search
    fd      # fast find
    jq      # json on the command line
    lazygit
    neovim
    nerd-fonts.hack
    herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs-unstable.cursor-cli
    gnomeExtensions.blur-my-shell
  ];

  programs.bash ={
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
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style)";
    };
  };
  programs.fzf.enable = true;
  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "nvim";

  home.file.".config/wezterm".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/herdr".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr"; 
  home.file.".claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json"; 
  home.file.".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".cursor/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
