{
  description = "dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      user = "bhanu";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      homeConfigurations.${user} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        # Makes `user` available as a module argument in home.nix.
        extraSpecialArgs = { inherit user; };
        modules = [
          ./home-manager/home.nix
        ];
      };
    };
}
