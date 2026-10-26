set shell := ["bash", "-euo", "pipefail", "-c"]

# List available recipes
default:
  @just --list

# Check all flake outputs
check:
  nix flake check

# Build the NixOS configuration without activating it
build host="lab":
  sudo nixos-rebuild build --flake ".#{{ host }}"

# Activate the NixOS and Home Manager configurations
switch host="lab":
  sudo nixos-rebuild switch --flake ".#{{ host }}"

# Activate a standalone Home Manager configuration
home configuration="linux":
  home-manager switch --flake ".#{{ configuration }}"

# Update flake inputs
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

# Show flake outputs
show:
  nix flake show
