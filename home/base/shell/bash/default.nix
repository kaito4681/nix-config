{ config, ... }:

{
  programs.bash = {
    enable = true;
    historyFile = "${config.xdg.stateHome}/bash/history";
    historySize = 100000;
    historyFileSize = 100000;
  };
}
