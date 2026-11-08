{ pkgs, username, ... }:
{
  environment.etc."t3code/policy.json".text = builtins.toJSON (
    import ../../modules/t3code-policy.nix
  );
  # Runs as kaito so projects and provider credentials stay in the user's home.
  systemd.services.t3code = {
    description = "T3 Code (Tailscale only)";
    wantedBy = [ "multi-user.target" ];
    wants = [
      "tailscaled.service"
      "network-online.target"
    ];
    after = [
      "tailscaled.service"
      "network-online.target"
    ];
    path = [
      pkgs.tailscale
      pkgs.git
      pkgs.openssh
      pkgs.bash
    ];
    environment = {
      HOME = "/home/${username}";
      T3CODE_TELEMETRY_ENABLED = "false";
      T3CODE_OTEL_SDK_DISABLED = "true";
      T3CODE_DISABLE_AUTO_UPDATE = "1";
    };
    script = ''
      # Fail closed while logged out/offline; retry when the tailnet returns.
      address=$(tailscale ip -4)
      test -n "$address"
      export PATH="/home/${username}/.nix-profile/bin:/etc/profiles/per-user/${username}/bin:$PATH"
      exec ${
        pkgs.callPackage ../../pkgs/t3code { }
      }/bin/t3 serve --host "$address" --port 3773 --no-browser
    '';
    serviceConfig = {
      User = username;
      WorkingDirectory = "/home/${username}";
      Restart = "always";
      RestartSec = 10;
      UMask = "0077";
    };
  };
  # No LAN/public firewall opening. tailscale0 is already trusted in configuration.nix.
}
