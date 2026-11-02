{ lib, pkgs, ... }:

{
  # docker-client には buildx と compose のプラグインが含まれる。
  home.packages = with pkgs; [
    docker-client
    colima
  ];

  # Docker が書き換えるファイルなので、無いときだけ Colima を既定のコンテキストにして作る。
  home.activation.dockerConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [[ ! -e "$HOME/.docker/config.json" ]]; then
      run install -d -m 700 "$HOME/.docker"
      run install -m 600 ${
        pkgs.writeText "docker-config.json" (builtins.toJSON { currentContext = "colima"; })
      } "$HOME/.docker/config.json"
    fi
  '';
}
