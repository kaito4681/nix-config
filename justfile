set shell := ["bash", "-euo", "pipefail", "-c"]

mod home 'just/home.just'
mod nixos 'just/nixos.just'

# コマンド一覧
default:
  @just --list

# 構成の検証
check:
  nix flake check path:.

# システム設定とユーザー設定を順に適用
apply host="lab":
  just nixos apply {{quote(host)}}
  just home apply {{quote(host)}}

# 依存パッケージの更新
update:
  #!/usr/bin/env bash
  set -euo pipefail

  if ! token="$(gh auth token --hostname github.com 2>/dev/null)"; then
    echo "GitHub authentication is required. Run: gh auth login" >&2
    exit 1
  fi

  if [[ -n "${NIX_CONFIG:-}" ]]; then
    export NIX_CONFIG="${NIX_CONFIG}"$'\n'"access-tokens = github.com=${token}"
  else
    export NIX_CONFIG="access-tokens = github.com=${token}"
  fi

  nix flake update

# 構成一覧
show:
  nix flake show path:.
