{
  nixpkgs,
  nixpkgsDarwin,
  home-manager,
  specialArgs,
}:

let
  mkHome =
    {
      source,
      system,
      hostName,
      modules ? [ ./base ],
    }:
    let
      privateModule = ../private/home/${hostName}.nix;
    in
    home-manager.lib.homeManagerConfiguration {
      pkgs = import source {
        inherit system;
        config.allowUnfree = true;
      };
      modules = modules ++ nixpkgs.lib.optional (builtins.pathExists privateModule) privateModule;
      extraSpecialArgs = specialArgs // {
        inherit hostName;
      };
    };
in
{
  lab = mkHome {
    source = nixpkgs;
    system = "x86_64-linux";
    hostName = "lab";
    modules = [ ./hosts/lab ];
  };

  linux = mkHome {
    source = nixpkgs;
    system = "x86_64-linux";
    hostName = "linux";
    modules = [ ./linux ];
  };

  darwin = mkHome {
    source = nixpkgsDarwin;
    system = "aarch64-darwin";
    hostName = "darwin";
    modules = [ ./darwin ];
  };
}
