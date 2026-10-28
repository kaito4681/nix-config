{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # gpueue の CRIU 4.2 パッケージは nixos-unstable の criu を上書きできないため，
    # nixpkgs は gpueue 側で固定されたもの (安定版) を使う．
    gpueue.url = "github:kaito4681/gpueue/stable";
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-darwin,
      home-manager,
      gpueue,
      ...
    }:
    let
      settings = import ./settings.nix;
      specialArgs = settings;
    in
    {
      nixosConfigurations = import ./nixos {
        inherit nixpkgs gpueue specialArgs;
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
