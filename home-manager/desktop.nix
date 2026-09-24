# Additions for a machine with a GNOME desktop: terminal, fonts, GNOME settings
# and extensions. Imported on top of common.nix; never used on headless servers.
{ config, lib, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in

{
  # GPU drivers for Nix GUI apps like wezterm (common.nix leaves them off).
  targets.genericLinux.gpu.enable = true;

  home.packages = with pkgs; [
    wezterm # default terminal
    nerd-fonts.hack
    wl-clipboard # wl-copy / wl-paste: Neovim's clipboard tool on Wayland
    gnomeExtensions.blur-my-shell
  ];
  fonts.fontconfig.enable = true;

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
        "tiling-assistant@ubuntu.com"
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

    "org/gnome/settings-daemon/plugins/media-keys" = {
      terminal = [ ];
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "WezTerm";
      command = "${pkgs.wezterm}/bin/wezterm";   # full path: GNOME's PATH doesn't include ~/.nix-profile
      binding = "<Control><Alt>t";
    };
  };

  # Apps that ask for a terminal open wezterm.
  xdg.configFile = {
    "xdg-terminals.list".text = "org.wezfurlong.wezterm.desktop\n";
    "ubuntu-xdg-terminals.list".text = "org.wezfurlong.wezterm.desktop\n";
    "GNOME-xdg-terminals.list".text = "org.wezfurlong.wezterm.desktop\n";
  };

  home.file.".config/wezterm".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
}
