{
  lib,
  pkgs,
  username,
  ...
}:

{
  imports = [
    ./ssh.nix
    ./shell
  ];

  home.username = username;
  home.homeDirectory = lib.mkDefault "/home/${username}";
  home.stateVersion = "26.05";

  home.packages =
    with pkgs;
    [
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

      # ユーティリティ
      tree
      unzip
      zip
      fastfetch

      # シェル関連ツール
      sheldon

      lefthook
      just

      hyperfine
      bat
      tmux
      perl
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux (
      with pkgs;
      [
        xdg-utils
        wl-clipboard
        xclip
      ]
    );

  programs.vim.enable = true;
  programs.neovim.enable = true;
  programs.neovim.defaultEditor = true;

  programs.home-manager.enable = true;
}
