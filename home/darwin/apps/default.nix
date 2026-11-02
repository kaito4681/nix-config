{ ... }:

{
  targets.darwin.defaults."org.hammerspoon.Hammerspoon".MJConfigFile =
    "~/.config/hammerspoon/init.lua";

  xdg.configFile = {
    "ghostty/config".source = ./ghostty/config;
    "ghostty/vscode_bridge.py".source = ./ghostty/vscode_bridge.py;
    "hammerspoon" = {
      source = ./hammerspoon;
      recursive = true;
    };
  };
}
