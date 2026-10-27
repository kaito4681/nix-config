{ flake }:

let
  runners = {
    x86_64-linux = "ubuntu-24.04";
    aarch64-linux = "ubuntu-24.04-arm";
    aarch64-darwin = "macos-latest";
    # Intel 向けの標準ランナーには latest ラベルがない。
    x86_64-darwin = "macos-26-intel";
  };
  entries =
    kind: configurations: suffix:
    map (
      name:
      let
        system =
          (
            if kind == "home" then
              configurations.${name}.activationPackage
            else
              configurations.${name}.config.system.build.toplevel
          ).system;
      in
      {
        inherit kind name system;
        runner = runners.${system};
        target = "${
          if kind == "home" then "homeConfigurations" else "nixosConfigurations"
        }.${name}.${suffix}";
      }
    ) (builtins.attrNames configurations);
in
{
  include =
    entries "home" flake.homeConfigurations "activationPackage"
    ++ entries "nixos" flake.nixosConfigurations "config.system.build.toplevel";
}
