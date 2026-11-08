{ lib, pkgs, ... }:
let
  policy = import ../modules/t3code-policy.nix;
in
{
  launchd.user.envVariables = {
    T3CODE_TELEMETRY_ENABLED = "false";
    T3CODE_OTEL_SDK_DISABLED = "true";
    T3CODE_DISABLE_AUTO_UPDATE = "1";
  };
  environment.systemPackages = [ (pkgs.callPackage ../pkgs/t3code { }) ];
  # T3 Code reads this administrator-owned path even when launched from Finder.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    install -d -m 0755 -o root -g wheel '/Library/Application Support/T3Code'
    install -m 0644 -o root -g wheel ${pkgs.writeText "t3code-policy.json" (builtins.toJSON policy)} '/Library/Application Support/T3Code/policy.json'
  '';
}
