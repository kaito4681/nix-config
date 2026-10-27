{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    {
      nixpkgs,
      nixpkgs-darwin,
      home-manager,
      ...
    }:
    let
      settings = import ./settings.nix;
      specialArgs = settings;
    in
    {
      nixosConfigurations = import ./hosts/nixos {
        inherit nixpkgs specialArgs;
      };

      homeConfigurations = import ./home {
        inherit nixpkgs home-manager specialArgs;
        nixpkgsDarwin = nixpkgs-darwin;
      };

      # 初回適用に使う Home Manager コマンド
      packages = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-darwin" ] (system: {
        home-manager = home-manager.packages.${system}.home-manager;
      });
    };
}
