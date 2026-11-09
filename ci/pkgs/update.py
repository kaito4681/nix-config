#!/usr/bin/env python3
"""Update registered GitHub stable-release pins, verifying every downloaded asset."""
import base64
import hashlib
import json
import os
from pathlib import Path
import re
import tempfile
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "ci/pkgs/packages.json"


def version_tuple(value):
    match = re.fullmatch(r"v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)", value)
    if not match:
        raise ValueError(f"Not a stable release version: {value!r}")
    return tuple(map(int, match.groups()))


def verified_hash(asset, name, version, repository):
    url = asset["browser_download_url"]
    if url != f"https://github.com/{repository}/releases/download/v{version}/{name}":
        raise ValueError(f"Unexpected release URL for {name}")
    expected = asset.get("digest") or ""
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


def update_package(package, config):
    pin = ROOT / config["pin"]
    current = json.loads(pin.read_text())
    repository = config["repository"]
    headers = {"Accept": "application/vnd.github+json", "User-Agent": "nix-config-package-updater"}
    if token := os.environ.get("GH_TOKEN"):
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(f"https://api.github.com/repos/{repository}/releases/latest", headers=headers)
    with urllib.request.urlopen(request, timeout=30) as response:
        release = json.load(response)
    version = release["tag_name"].removeprefix("v")
    latest = version_tuple(release["tag_name"])
    if release["draft"] or release["prerelease"]:
        raise ValueError("Refusing draft/prerelease")
    if latest <= version_tuple(current["version"]):
        return None
    assets = {asset["name"]: asset for asset in release["assets"]}
    hashes = {}
    for system, template in config["assets"].items():
        name = template.format(version=version)
        hashes[system] = verified_hash(assets[name], name, version, repository)
    return {
        "pin": pin, "value": {"version": version, "hashes": hashes},
        "summary": f"- {package}: {current['version']} → {version} (https://github.com/{repository}/releases/tag/v{version})",
        "checks": [{"package": package, **check} for check in config["checks"]],
    }


def main():
    packages = json.loads(MANIFEST.read_text())
    # Validate every asset of every package before changing any pin.
    updates = [result for package, config in packages.items()
               if (result := update_package(package, config)) is not None]
    if not updates:
        output("changed", "false")
        return
    for update in updates:
        update["pin"].write_text(json.dumps(update["value"], indent=2) + "\n")
    body = Path(tempfile.gettempdir()) / "package-update-pr.md"
    body.write_text(
        "Update pinned packages from their official stable releases.\n\n"
        + "\n".join(update["summary"] for update in updates)
        + "\n\nAll assets were downloaded and their SHA-256 digests and sizes verified "
        "against GitHub release metadata. Full configuration CI and registered package "
        "checks must pass before this exact commit is automatically merged.\n"
    )
    output("changed", "true")
    output("body-path", body)
    output("paths", ",".join(str(update["pin"].relative_to(ROOT)) for update in updates))
    output("matrix", json.dumps({"include": [check for update in updates for check in update["checks"]]}))


if __name__ == "__main__":
    main()
