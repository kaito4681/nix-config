{
  config,
  lib,
  pkgs,
  ...
}:

let
  sharedInit = shell: ''
    # 秘密設定の読み込み
    if [ -r "${config.xdg.configHome}/${shell}/secret.${shell}" ]; then
      . "${config.xdg.configHome}/${shell}/secret.${shell}"
    fi

    # Linux 用のクリップボード・URL 操作
    ${lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
      ${builtins.readFile ./clipboard.sh}
      ${builtins.readFile ./open.sh}
    ''}
  '';
in
{
  imports = [
    ./env.nix
    ./path.nix
    ./aliases.nix
  ];

  # Bash の共通初期化
  programs.bash.initExtra = lib.mkIf config.programs.bash.enable (sharedInit "bash");

  # zsh の共通初期化
  programs.zsh.initContent = lib.mkIf config.programs.zsh.enable (sharedInit "zsh");
}
