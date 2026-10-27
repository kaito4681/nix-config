# NixOS and Home Manager configuration

[日本語](README.ja.md)

## Setup

On Linux (other than NixOS) or macOS, install [Nix](https://github.com/NixOS/nix-installer)
first.

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
```

Clone this repository.

```bash
nix shell nixpkgs#git --command git clone https://github.com/kaito4681/nix-config.git ~/ghq/github.com/kaito4681/nix-config
cd ~/ghq/github.com/kaito4681/nix-config
```

Open a new terminal after installation.

Before applying, edit `username`, `githubName`, and `githubEmail` in
`settings.nix` for your own account, then run the following command to fetch `sshKeys`:

```bash
nix shell --inputs-from . nixpkgs#python3 nixpkgs#openssh --command python3 ci/ssh-keys/update.py
```

```bash
# NixOS
sudo nixos-rebuild switch --flake .#<host>
just home apply <host>

# Linux (other than NixOS)
nix run .#home-manager -- switch --flake .#linux

# macOS (Apple Silicon)
nix run .#home-manager -- switch --flake .#darwin
```

Log in to GitHub.

```bash
gh auth login
```

On NixOS, also log in to Tailscale:

```bash
sudo tailscale login
sudo systemctl restart tailscaled-set.service
```

Approve the advertised routes and exit node in the
[Tailscale admin console](https://console.tailscale.com/admin/machines).

On NixOS, reload environment variables for Docker:

```bash
source /etc/set-environment
```

## Commands

```bash
just                       # List commands
just update                # Update dependencies
just apply <host>          # Apply NixOS and Home Manager
just home apply <host>     # Apply Home Manager
just home build <host>     # Build Home Manager without applying
just nixos apply <host>    # Apply NixOS
just nixos build <host>    # Build NixOS without applying
just check                 # Check the flake
just show                  # Show configurations
```

NixOS hosts: `lab`. Home Manager hosts: `lab`, `linux`, `darwin` (Apple Silicon).
