{ pkgs, username, githubName, githubEmail, ... }:

{
  imports = [ ./nix/git.nix ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    curl
    wget
    codex

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

  # This replaces the vim entry in environment.systemPackages.
  programs.vim.enable = true;

  programs.home-manager.enable = true;
}
