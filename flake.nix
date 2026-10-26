{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { nixpkgs, home-manager, ... }:
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
      };
    };
}
