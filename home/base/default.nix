{ pkgs, username, ... }:

{
  imports = [ ./git.nix ];

  home.username = username;
  home.homeDirectory =
    if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    curl
    wget
    just

    # ai-agents
    codex
    claude-code

    # python
    python3
    uv
    ruff
    ty

    # System monitoring
    htop

    # Search
    ripgrep
    fd
    fzf

    # File viewing
    bat

    # Utilities
    tree
    unzip
    zip
    fastfetch
  ];

  programs.vim.enable = true;
  programs.neovim.enable = true;

  programs.home-manager.enable = true;
}
