{
  description = "Kaito's Home Manager configuration";

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
    hostname = "nixos";
  in {
    homeConfigurations."${username}@${hostname}" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [ ./home.nix ];
      extraSpecialArgs = {
        inherit username githubName githubEmail;
      };
    };
  };
}
