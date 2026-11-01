{
  lib,
  pkgs,
  ...
}:

let
  appPath = "/Applications/Tailscale.app";
in
{
  # Tailscale CLIだけをシステム共通のPATHに追加
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "tailscale" ''
      export TAILSCALE_BE_CLI=1
      exec ${lib.escapeShellArg "${appPath}/Contents/MacOS/Tailscale"} "$@"
    '')
  ];
}
