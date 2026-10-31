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
      # Nix
      nixfmt

      # AI エージェント
      codex
      claude-code

      # JavaScript / TypeScript
      nodejs_latest
      pnpm
      bun
      deno

      # Python
      python3
      uv
      ruff
      ty

      # Rust
      rustc
      cargo
      rustfmt
      clippy

      # Go
      go
      gopls

      # Perl
      perl

      # Git・開発支援
      git-xet
      lefthook
      swiftlint
      just

      # ファイル・テキスト操作
      ripgrep
      fd
      tree
      yazi
      bat
      unzip
      zip

      # 画像処理
      imagemagick

      # ターミナル・システム監視
      tmux
      htop
      fastfetch
      hyperfine

      # 通信・ネットワーク調査
      curl
      wget
      nmap
      iperf3
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
