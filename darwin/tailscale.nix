{
  config,
  lib,
  pkgs,
  ...
}:

let
  package = pkgs.tailscale-gui;
  appPath = "/Applications/Tailscale.app";
in
{
  assertions = [
    {
      assertion = !config.services.tailscale.enable; # GUI版と別のtailscaledを同時に起動しない。
      message = "Tailscale GUI cannot be combined with services.tailscale.enable.";
    }
  ];

  # GUIを重複配置せず、CLIだけをシステム共通のPATHへ公開する。
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "tailscale" ''
      export TAILSCALE_BE_CLI=1
      exec ${lib.escapeShellArg "${appPath}/Contents/MacOS/Tailscale"} "$@"
    '')
  ];

  # 既存の別配布版や起動中のアプリを、適用時に無断で上書きしない。
  system.checks.text = lib.mkAfter ''
    if [[ -e ${lib.escapeShellArg "${appPath}/Contents/Info.plist"} ]]; then
      currentId=$(/usr/bin/plutil -extract CFBundleIdentifier raw -o - ${lib.escapeShellArg "${appPath}/Contents/Info.plist"})
      packageId=$(/usr/bin/plutil -extract CFBundleIdentifier raw -o - ${package}/Applications/Tailscale.app/Contents/Info.plist)
      if [[ "$currentId" != "$packageId" ]]; then
        echo "Tailscale distribution differs. Migrate the existing app before applying this configuration." >&2
        exit 1
      fi
      if /usr/bin/pgrep -x Tailscale >/dev/null; then
        echo "Quit Tailscale before applying this configuration." >&2
        exit 1
      fi
    fi
  '';

  # システム拡張のため、Nix Apps配下ではなく/Applications直下へ実体を配置する。
  system.activationScripts.applications.text = lib.mkAfter ''
    install -o root -g wheel -m0555 -d ${lib.escapeShellArg appPath}
    ${lib.getExe pkgs.rsync} \
      --checksum --copy-unsafe-links --archive --delete --chmod=-w --no-group --no-owner \
      ${package}/Applications/Tailscale.app/ ${lib.escapeShellArg "${appPath}/"}
  '';
}
