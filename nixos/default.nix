{
  nixpkgs,
  gpueue,
  specialArgs,
}:

let
  hostNames = [ "lab" ];

  mkHost =
    hostName:
    let
      privateModule = ../private/nixos/${hostName}/default.nix;
    in
    nixpkgs.lib.nixosSystem {
      specialArgs = specialArgs // {
        inherit hostName;
      };

      modules = [
        gpueue.nixosModules.default
        ./${hostName}/configuration.nix
        { networking.hostName = hostName; }
      ]
      ++ nixpkgs.lib.optional (builtins.pathExists privateModule) privateModule;
    };
in
nixpkgs.lib.genAttrs hostNames mkHost
