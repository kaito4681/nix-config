set shell := ["bash", "-euo", "pipefail", "-c"]
set working-directory := ".."

# NixOS のコマンド一覧
default:
  @just --list nixos

# システム設定の適用
apply host="lab":
  sudo nixos-rebuild switch --flake {{quote("path:.#" + host)}}

# システム設定のビルド
build host="lab":
  nix build --no-link {{quote("path:.#nixosConfigurations." + host + ".config.system.build.toplevel")}}
