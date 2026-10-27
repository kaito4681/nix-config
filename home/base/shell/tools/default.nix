{ ... }:

{
  imports = [ ./starship.nix ];

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = false;
  };
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = false;
  };
  programs.direnv = {
    enable = true;
    enableZshIntegration = false;
    nix-direnv.enable = true;
  };
  programs.mise = {
    enable = true;
    enableZshIntegration = false;
  };
}
