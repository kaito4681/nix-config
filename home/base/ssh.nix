{
  lib,
  pkgs,
  githubName,
  sshKeys,
  ...
}:

let
  # GitHub の公開鍵．GitHub Actionで更新を監視する．
  authorizedKeys = pkgs.fetchurl {
    url = "https://github.com/${githubName}.keys";
    hash = sshKeys.hash;
  };
in
{
  # GitHub の公開鍵を ~/.ssh/authorized_keys に置く．
  # sshd の StrictModes は /nix/store (group 書き込み可) へのシンボリックリンクを拒否するため，
  # home.file ではなく実ファイルとしてコピーする．
  home.activation.authorizedKeys = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run install -d -m 700 "$HOME/.ssh"
    run rm -f "$HOME/.ssh/authorized_keys"
    run install -m 600 ${authorizedKeys} "$HOME/.ssh/authorized_keys"
  '';
}
