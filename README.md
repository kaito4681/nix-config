# NixOS and Home Manager configuration

## Initial setup

On Linux (other than NixOS) or macOS, install [Nix](https://github.com/NixOS/nix-installer)
first.

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
```

Open a new terminal after installation.

Before applying, customize `settings.nix` (username, GitHub account, email, and
SSH public key information) for your own account. After editing `githubName`,
update `sshKeys` with:

```bash
nix shell --inputs-from . nixpkgs#python3 nixpkgs#openssh --command python3 ci/ssh-keys/update.py
```

These keys authorize SSH login to your machine.

Apply the configuration for your OS:

```bash
# NixOS
sudo nixos-rebuild switch --flake .#lab
just home apply lab

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
just apply lab             # Apply NixOS and Home Manager
just home apply <host>     # Apply Home Manager
just home build <host>     # Build Home Manager without applying
just nixos apply lab       # Apply NixOS
just nixos build lab       # Build NixOS without applying
just check                 # Check the flake
just show                  # Show configurations
```

Home Manager hosts: `lab`, `linux`, `darwin` (Apple Silicon).
