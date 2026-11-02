{ username, ... }:

{
  imports = [
    ../base
    ./apps
    ./docker.nix
    ./shell
  ];

  home.homeDirectory = "/Users/${username}";
}
