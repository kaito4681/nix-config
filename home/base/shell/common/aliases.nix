{ ... }:

{
  home.shellAliases = {
    # ディレクトリ移動
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
    "....." = "cd ../../../..";

    # ファイル一覧
    l = "eza -l --header --time-style=relative";
    ll = "eza -l --header --time-style=relative";
    lla = "eza -la --header --time-style=relative";

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
}
