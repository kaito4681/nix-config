{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { nixpkgs, nixpkgs-darwin, home-manager, ... }:
    let
      settings = import ./settings.nix;
      specialArgs = settings;
    in {
      nixosConfigurations = import ./hosts/nixos {
        inherit nixpkgs home-manager specialArgs;
        inherit (settings) username;
      };

      homeConfigurations = import ./home {
        inherit nixpkgs home-manager specialArgs;
        nixpkgsDarwin = nixpkgs-darwin;
      };
    };
}
