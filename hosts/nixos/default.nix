{ nixpkgs, specialArgs }:

let
  hostNames = [ "lab" ];

  mkHost =
    hostName:
    nixpkgs.lib.nixosSystem {
      specialArgs = specialArgs // {
        inherit hostName;
      };

      modules = [
        ./${hostName}/configuration.nix
        { networking.hostName = hostName; }
      ];
    };
in
nixpkgs.lib.genAttrs hostNames mkHost
