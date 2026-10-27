{ lib, pkgs, ... }:

let
  nvidiaAlias = ''
    if command -v nvidia-smi >/dev/null 2>&1; then
      alias ns='nvidia-smi'
    fi
  '';
in
{
  home.shellAliases = {
    # ディレクトリ移動
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
    "....." = "cd ../../../..";

    # ファイル一覧
    ls = "eza --icons=auto --group-directories-first";
    l = "eza -l --header --icons=auto --time-style=relative --group-directories-first";
    ll = "eza -l --header --icons=auto --time-style=relative --group-directories-first";
    la = "eza -a --icons=auto --group-directories-first";
    lla = "eza -la --header --icons=auto --time-style=relative --group-directories-first";
    lt = "eza --tree --icons=auto --group-directories-first";

    # Git 操作
    g = "git";
    gtree = "git ls-files | tree --fromfile";

    # Bun の開発・ビルド
    b = "bun";
    bd = "bun dev";
    bb = "bun run build";
    bs = "bun start";
    bbs = "bun run build && bun start";

    # VS Code で管理者権限のファイルを編集
    sudocode = ''SUDO_EDITOR="$(which code) --wait" sudoedit'';
    scode = ''SUDO_EDITOR="$(which code) --wait" sudoedit'';
  };

  # NVIDIA GPU の状態表示
  programs.bash.initExtra = lib.mkIf pkgs.stdenv.hostPlatform.isLinux nvidiaAlias;
  programs.zsh.initContent = lib.mkIf pkgs.stdenv.hostPlatform.isLinux nvidiaAlias;
}
