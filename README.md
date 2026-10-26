# NixOS and Home Manager configuration

## Initial setup

Apply the NixOS and Home Manager configurations first.

```bash
sudo nixos-rebuild switch --flake .#lab
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

## Update

```bash
just update && just switch
```
