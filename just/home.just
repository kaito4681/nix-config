set shell := ["bash", "-euo", "pipefail", "-c"]
set working-directory := ".."

default_host := if os() == "macos" { "darwin" } else { "linux" }

# Home Manager のコマンド一覧
default:
  @just --list home

# ユーザー設定の適用
apply host=default_host backup="":
  nix run path:.#home-manager -- switch --flake {{quote("path:.#" + host)}} {{if backup == "" { "" } else { "-b " + quote(backup) }}}

# ユーザー設定のビルド
build host=default_host:
  nix build --no-link {{quote("path:.#homeConfigurations." + host + ".activationPackage")}}
