set shell := ["bash", "-euo", "pipefail", "-c"]
set working-directory := ".."

# nix-darwin のコマンド一覧
default:
  @just --list darwin

# システム設定の適用
apply host="darwin":
  sudo nix run path:.#darwin-rebuild -- switch --flake {{quote("path:.#" + host)}}

# システム設定のビルド
build host="darwin":
  nix build --no-link {{quote("path:.#darwinConfigurations." + host + ".config.system.build.toplevel")}}
