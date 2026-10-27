{
  pkgs,
  githubName,
  sshKeys,
  ...
}:

{
  # GitHub の公開鍵を ~/.ssh/authorized_keys に置く．
  # GitHub Actionで更新を監視する．
  home.file.".ssh/authorized_keys".source = pkgs.fetchurl {
    url = "https://github.com/${githubName}.keys";
    hash = sshKeys.hash;
  };
}
