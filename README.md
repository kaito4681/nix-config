# NixOS and Home Manager configuration

## Initial setup

Apply NixOS first, then the standalone Home Manager configuration.

```bash
sudo nixos-rebuild switch --flake path:.#lab
just home apply lab
```

Log in to GitHub and Tailscale.

```bash
# GitHub
gh auth login
```

```bash
# Tailscale
sudo tailscale login
sudo systemctl restart tailscaled-set.service
# Approve the advertised routes and exit node:
# https://console.tailscale.com/admin/machines
```

```bash
# Reload environment variables for Docker
source /etc/set-environment
```

## Update

```bash
just update
just apply lab
```

## Commands

NixOS and Home Manager are managed independently. NixOS controls system
services, drivers, and the login shell. Home Manager controls shell settings,
Git, and user packages.

```bash
just apply lab           # Apply NixOS, then Home Manager
just home apply lab      # Apply lab's user configuration
just home build lab      # Build without applying
just nixos apply lab     # Apply lab's system configuration
just nixos build lab     # Build without applying
just check               # Check the flake
just show                # Show configurations
```

`just home` and `just nixos` list their available commands.
Home Manager configurations are `lab`, `linux` (generic x86_64 Linux), and
`darwin` (Apple Silicon). Without a host argument, Home Manager selects
`linux` or `darwin` from the current OS; NixOS defaults to `lab`.

Host-specific user settings belong in `home/hosts/lab/default.nix`.
Shared user settings remain in `home/base/`.

## Migration from integrated Home Manager

The NixOS configuration no longer includes the Home Manager module.
Build both configurations before switching, then apply NixOS followed by
Home Manager from the same terminal:

```bash
just home build lab
just nixos build lab
just nixos apply lab
just home apply lab
```

The NixOS switch removes the old `home-manager-kaito.service` and the
system-managed user packages. `just` remains installed by NixOS, and
`just home apply lab` uses the Home Manager version pinned in `flake.lock`,
so it works even before the `home-manager` command is installed.
The standalone activation installs the user packages in the user's Nix
profile. Log in again after completing both steps.

The old `just switch`, `just build`, and `just home lab` commands are replaced
by `just nixos apply`, `just nixos build`, and `just home apply lab`.
