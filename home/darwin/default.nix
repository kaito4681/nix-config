{ username, ... }:

{
  imports = [
    ../base
    ./shell
  ];

  home.homeDirectory = "/Users/${username}";
}
