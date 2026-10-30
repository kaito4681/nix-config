{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # gpueue の CRIU 4.2 パッケージは nixos-unstable の criu を上書きできないため，
    # nixpkgs は gpueue 側で固定されたもの (安定版) を使う．
    gpueue.url = "github:kaito4681/gpueue/stable";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-darwin,
      home-manager,
      gpueue,
      git-hooks,
      ...
    }:
    let
      settings = import ./settings.nix;
      specialArgs = settings;
      forEachSystem = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-darwin"
      ];
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
      packages = forEachSystem (system: {
        home-manager = home-manager.packages.${system}.home-manager;
      });

      formatter = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          inherit (self.checks.${system}.pre-commit-check.config) package configFile;
        in
        pkgs.writeShellScriptBin "format" ''
          exec ${pkgs.lib.getExe package} run --all-files --config ${configFile} "$@"
        ''
      );

      checks = forEachSystem (system: {
        pre-commit-check = git-hooks.lib.${system}.run {
          src = ./.;
          hooks.nixfmt.enable = true;
        };
      });

      devShells = forEachSystem (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
          packages = self.checks.${system}.pre-commit-check.enabledPackages;
        };
      });
    };
}
