{ username, ... }:

{
  imports = [
    ../base
    ./apps
    ./docker.nix
    ./shell
  ];

  # Also reaches the desktop shell-environment import; policy is the primary control.
  home.sessionVariables = {
    T3CODE_TELEMETRY_ENABLED = "false";
    T3CODE_OTEL_SDK_DISABLED = "true";
    T3CODE_DISABLE_AUTO_UPDATE = "1";
  };

  home.homeDirectory = "/Users/${username}";
}
