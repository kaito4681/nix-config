set shell := ["bash", "-euo", "pipefail", "-c"]

mod add 'just/add.just'
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

# 依存パッケージと非公開設定の更新
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

  private_update=false
  if [[ -e private/.git ]]; then
    if [[ -n "$(git -C private status --porcelain)" ]]; then
      echo "Skipping private update: uncommitted changes exist."
    elif ! GH_PROMPT_DISABLED=1 GIT_TERMINAL_PROMPT=0 git -C private \
      -c credential.helper= -c 'credential.helper=!gh auth git-credential' \
      pull --ff-only; then
      echo "Skipping private update: pull failed; keeping the local checkout."
    else
      private_update=true
    fi
  fi

  if "$private_update" && [[ -f private/flake.nix ]]; then
    if ! nix flake update --flake path:./private; then
      echo "Skipping private lock update: keeping the existing lock file."
    fi
  fi

  nix flake update

# 構成一覧
show:
  nix flake show path:.
