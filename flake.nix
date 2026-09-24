{
  description = "dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    herdr.url = "github:herdrdev/herdr";
  };

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, herdr, ... }:
    let
      system = "x86_64-linux";
      user = "bhanu";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      pkgs-unstable = import nixpkgs-unstable { inherit system; config.allowUnfree = true; }
    in
    {
      homeConfigurations.${user} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit user herdr pkgs-unstable; };
        modules = [
          ./home-manager/home.nix
        ];
      };
    };
}
