{ nixpkgs, home-manager, specialArgs, username }:

let
  hostNames = [ "lab" ];

  mkHost = hostName:
    nixpkgs.lib.nixosSystem {
      specialArgs = specialArgs // { inherit hostName; };

      modules = [
        ./${hostName}/configuration.nix
        { networking.hostName = hostName; }

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = specialArgs;
          home-manager.users.${username} = import ../../home/base;
        }
      ];
    };
in
nixpkgs.lib.genAttrs hostNames mkHost
