{
  nixpkgs,
  gpueue,
  specialArgs,
}:

let
  hostNames = [ "lab" ];

  mkHost =
    hostName:
    nixpkgs.lib.nixosSystem {
      specialArgs = specialArgs // {
        inherit hostName;
      };

      modules = [
        gpueue.nixosModules.default
        ./${hostName}/configuration.nix
        { networking.hostName = hostName; }
      ];
    };
in
nixpkgs.lib.genAttrs hostNames mkHost
