{ nixpkgs, home-manager, specialArgs, username }:

{
  ${username} = home-manager.lib.homeManagerConfiguration {
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    modules = [ ./base ];
    extraSpecialArgs = specialArgs;
  };
}
