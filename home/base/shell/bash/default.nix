{ config, lib, ... }:

{
  programs.bash = {
    enable = true;
    historyFile = "${config.xdg.stateHome}/bash/history";
    historySize = 100000;
    historyFileSize = 100000;
    initExtra = lib.mkBefore ''
      mkdir -p "${config.xdg.stateHome}/bash"
    '';
  };
}
