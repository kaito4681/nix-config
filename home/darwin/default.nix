{ username, ... }:

{
  imports = [
    ../base
    ./apps
    ./shell
  ];

  home.homeDirectory = "/Users/${username}";
}
