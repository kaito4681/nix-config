# T3 Code: Nix-managed desktop and tailnet server

Both packages use the official release pinned in `pkgs/t3code/release.json` with fixed SHA-256 hashes. macOS keeps
its upstream signed app bundle intact; Linux keeps the Node SEA payload intact
and patches native dependencies for NixOS. GitHub Actions checks stable upstream releases every six hours (also manually via
Update T3 Code). It downloads both assets and verifies their SHA-256 digests and
sizes against GitHub release metadata, then opens/refreshes one update PR. Draft,
nightly, downgrade, incomplete, or mismatched releases are rejected. After all
configuration builds and both platform CLI/policy checks plus macOS signature
verification pass, Actions squash-merges only the verified PR head commit. The
workflow uses GITHUB_TOKEN and explicitly calls CI; no personal token or repository
Auto-merge toggle is needed. GitHub Actions must be allowed to create PRs in the
repository settings. A failed check keeps the PR open. Package-format or policy
incompatibilities require manual changes. Merging updates the repository pin;
installed machines update when their Nix configuration is next applied.

## Privacy

The machine-wide policy disables product analytics, relay traces, T3 Connect,
in-app updates, provider-version checks, and model-catalog downloads. OTLP
endpoints are locked empty. The launch environment also disables all OpenTelemetry
exports. Disabling Connect prevents publishing project/thread activity through its
relay. No T3 account is needed for direct Tailscale connections.

The macOS policy is installed at `/Library/Application Support/T3Code/policy.json`
by nix-darwin; the Linux policy is `/etc/t3code/policy.json`. Restart the desktop
or server after a policy change and run `t3 policy show` to verify the running
process loaded it. Policy works for Finder launches too; launchd exports the
privacy variables to new GUI processes. Log out/in if the GUI launch environment
has not refreshed.

This is an application privacy configuration, not an outbound firewall. Provider
CLIs, tools, Git operations, and Tailscale have their own network traffic and
settings. Separate browser/mobile builds can send their own relay diagnostics;
use the managed desktop app for this setup, rather than app.t3.codes. Provider
credentials and pairing tokens remain outside the Nix store and Git.

## Apply on macOS

From this checkout:

```sh
just darwin build
just darwin apply
just home apply darwin
```

Quit the old app and start the Nix-managed app in `/Applications/Nix Apps`.
Check the signature with `codesign --verify --deep --strict` and verify
`t3 policy show` before removing the old installation:

```sh
brew uninstall --cask t3-code
```

Do not use `--zap`: preserve existing threads and authentication. If the app was
installed temporarily with `nix profile add .#t3code`, remove that profile entry
after nix-darwin provides it to avoid two Nix-managed launch paths.

## Apply on lab

Apply this branch in lab's existing checkout (including its local private modules):

```sh
just nixos build lab
just nixos apply lab
sudo systemctl status t3code
```

The system service runs as `kaito`, using that user's existing provider credentials
and Home Manager tools. It obtains the current IPv4 address from `tailscale ip -4`
at each start and listens only there, on port 3773. No public/LAN TCP port is opened.
The existing firewall trusts tailscale0, so tailnet ACLs determine who can reach it;
T3's pairing authentication remains enabled. Logged-out Tailscale causes startup
to fail and retry. Restart the service if its Tailscale IP changes.

```sh
sudo systemctl restart t3code
ss -ltn 'sport = :3773'
nix run .#t3code -- policy show
nix run .#t3code -- pair --label macbook
```

On the Mac, open Settings > Environments > Add a computer and use the generated
app link/pairing URL. The host is lab's Tailscale IP (currently
`http://100.109.145.96:3773`). HTTP and WebSocket traffic are encrypted by Tailscale
between the devices; no T3 Connect, public relay, Funnel, or public certificate is
required. Keep the one-time pairing URL private and use it before its five-minute
expiry. Do not run `t3 service install`: NixOS owns the service.

Back up `~/.t3` before version changes. A Nix rollback restores the binary, but
may also require restoring matching application data if the database was migrated.
