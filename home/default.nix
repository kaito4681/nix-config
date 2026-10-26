{ nixpkgs, nixpkgsDarwin, home-manager, specialArgs }:

{
  linux = home-manager.lib.homeManagerConfiguration {
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    modules = [ ./base ];
    extraSpecialArgs = specialArgs;
  };

  darwin = home-manager.lib.homeManagerConfiguration {
    pkgs = nixpkgsDarwin.legacyPackages.aarch64-darwin;
    modules = [ ./base ];
    extraSpecialArgs = specialArgs;
  };
}
