{ pkgs, user, ... }:

{
  home.username = user;
  home.homeDirectory = "/home/${user}";

  # The Home Manager release this config was first written against.
  # Don't bump it when upgrading nixpkgs; it only controls stateful defaults.
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    ripgrep
  ];

  # Lets Home Manager install and manage itself, so `home-manager` is on PATH.
  programs.home-manager.enable = true;
}
