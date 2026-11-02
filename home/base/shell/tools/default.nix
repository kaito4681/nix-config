{ ... }:

{
  imports = [
    ./git.nix
    ./starship.nix
    ./eza.nix
  ];

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
  home.sessionVariables._ZO_ECHO = "1"; # 移動先のディレクトリを表示する。
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
  };
}
