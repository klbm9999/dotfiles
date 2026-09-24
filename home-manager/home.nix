{ config, lib, pkgs, user, ... }:

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
  };

  home.username = user;
  home.homeDirectory = "/home/${user}";

  # The Home Manager release this config was first written against.
  # Don't bump it when upgrading nixpkgs; it only controls stateful defaults.
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    wezterm
    ripgrep
  ];

  # Lets Home Manager install and manage itself, so `home-manager` is on PATH.
  programs.home-manager.enable = true;

  home.file.".config/wezterm".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
}
