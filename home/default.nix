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
    home-manager.lib.homeManagerConfiguration {
      pkgs = import source {
        inherit system;
        config.allowUnfree = true;
      };
      inherit modules;
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
  };

  darwin = mkHome {
    source = nixpkgsDarwin;
    system = "aarch64-darwin";
    hostName = "darwin";
  };
}
