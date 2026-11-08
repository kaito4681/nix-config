#!/usr/bin/env python3
"""Pin a newer official stable release after verifying both downloaded assets."""
import base64
import hashlib
import json
import os
from pathlib import Path
import re
import tempfile
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
PIN = ROOT / "pkgs/t3code/release.json"
REPO = "pingdotgg/t3code"


def version_tuple(value):
    match = re.fullmatch(r"v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)", value)
    if not match:
        raise ValueError(f"Not a stable release version: {value!r}")
    return tuple(map(int, match.groups()))


def verified_hash(asset, name, version):
    url = asset["browser_download_url"]
    if url != f"https://github.com/{REPO}/releases/download/v{version}/{name}":
        raise ValueError(f"Unexpected release URL for {name}")
    expected = asset.get("digest", "")
    if not re.fullmatch(r"sha256:[0-9a-f]{64}", expected):
        raise ValueError(f"Missing upstream SHA-256 digest for {name}")
    digest = hashlib.sha256()
    size = 0
    with urllib.request.urlopen(url, timeout=120) as response:
        while chunk := response.read(1024 * 1024):
            digest.update(chunk)
            size += len(chunk)
    if size != asset["size"] or f"sha256:{digest.hexdigest()}" != expected:
        raise ValueError(f"Downloaded asset failed size/digest verification: {name}")
    return "sha256-" + base64.b64encode(digest.digest()).decode()


def output(key, value):
    print(f"{key}={value}")
    if path := os.environ.get("GITHUB_OUTPUT"):
        with open(path, "a") as stream:
            stream.write(f"{key}={value}\n")


def main():
    current = json.loads(PIN.read_text())
    headers = {"Accept": "application/vnd.github+json", "User-Agent": "nix-config-t3code-updater"}
    if token := os.environ.get("GH_TOKEN"):
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(f"https://api.github.com/repos/{REPO}/releases/latest", headers=headers)
    with urllib.request.urlopen(request, timeout=30) as response:
        release = json.load(response)
    version = release["tag_name"].removeprefix("v")
    latest = version_tuple(release["tag_name"])
    if release["draft"] or release["prerelease"]:
        raise ValueError("Refusing draft/prerelease")
    if latest <= version_tuple(current["version"]):
        output("changed", "false")
        return
    assets = {asset["name"]: asset for asset in release["assets"]}
    names = {
        "aarch64-darwin": f"T3-Code-{version}-arm64.zip",
        "x86_64-linux": f"t3-{version}-linux-x64.tar.gz",
    }
    # Validate everything before replacing the pin; partial releases fail closed.
    updated = {"version": version, "hashes": {
        system: verified_hash(assets[name], name, version) for system, name in names.items()
    }}
    PIN.write_text(json.dumps(updated, indent=2) + "\n")
    body = Path(tempfile.gettempdir()) / "t3code-update-pr.md"
    body.write_text(
        f"Update official T3 Code from {current['version']} to {version}.\n\n"
        f"Release: https://github.com/{REPO}/releases/tag/v{version}\n\n"
        "Both official assets were downloaded and their SHA-256 digests and sizes "
        "verified against GitHub release metadata. The existing privacy policy is unchanged.\n\n"
        "The update workflow builds all configurations and verifies the CLI, privacy policy, "
        "and macOS signature before merging this exact commit.\n"
    )
    output("changed", "true")
    output("version", version)
    output("body-path", body)


if __name__ == "__main__":
    main()
