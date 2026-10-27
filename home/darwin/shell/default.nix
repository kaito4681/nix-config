{ config, lib, ... }:

{
  home.sessionVariables.BASH_SILENCE_DEPRECATION_WARNING = "1";
  home.sessionPath = lib.mkAfter [ "/Library/TeX/texbin" ];

  home.shellAliases = {
    tailscale = "/Applications/Tailscale.app/Contents/MacOS/Tailscale";
    "draw.io" = "/Applications/draw.io.app/Contents/MacOS/draw.io";
  };

  # Ghostty のタブ・ウィンドウ操作
  programs.zsh.initContent = lib.mkIf config.programs.zsh.enable (
    lib.mkOrder 1020 ''
      zsh-defer -m -p -r source ${lib.escapeShellArg (toString ./ghostty.zsh)}
    ''
  );
}
