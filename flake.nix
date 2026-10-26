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
      username = "kaito";
      githubName = "kaito4681";
      githubEmail = "133554451+kaito4681@users.noreply.github.com";

      specialArgs = {
        inherit username githubName githubEmail;
      };
    in {
      nixosConfigurations = import ./hosts/nixos {
        inherit nixpkgs home-manager specialArgs username;
      };

      homeConfigurations = import ./home {
        inherit nixpkgs home-manager specialArgs username;
      };
    };
}
