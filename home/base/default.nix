{ lib, pkgs, username, ... }:

{
  imports = [ ./git.nix ./shell ];

  home.username = username;
  home.homeDirectory =
    if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${username}" else "/home/${username}";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    curl
    wget

    # Nix
    nixfmt

    # AI エージェント
    codex
    claude-code

    # Python 開発
    python3
    uv
    ruff
    ty

    # システム監視・ネットワーク調査
    htop
    nmap

    # ファイル・テキスト検索
    ripgrep
    fd
    fzf

    # ユーティリティ
    tree
    unzip
    zip
    fastfetch

    # シェル関連ツール
    direnv
    starship
    sheldon

    lefthook
    just

    hyperfine
    bat
    eza
    tmux
    zoxide
    perl
  ] ++ lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) (with pkgs; [
    xdg-utils
    wl-clipboard
    xclip
  ]);

  programs.vim.enable = true;
  programs.neovim.enable = true;
  programs.neovim.defaultEditor = true;

  programs.home-manager.enable = true;
}
