"""GitHub の公開鍵を検証し、変更時だけハッシュと PR 本文を更新する。"""

import json
import os
import re
import subprocess
import tempfile
from pathlib import Path


def run(*args):
    return subprocess.check_output(args, text=True).strip()


def fingerprints(content):
    result = set()
    for line in content.splitlines():
        if not line.strip():
            continue
        # authorized_keys のオプションや HTML 等を受け入れない。
        if not re.match(
            r"(?:ssh-|ecdsa-|sk-)[A-Za-z0-9@._+-]+ [A-Za-z0-9+/]+=*(?:\s|$)", line
        ):
            raise ValueError("Unexpected public key format")
        with tempfile.NamedTemporaryFile(mode="w+", suffix=".pub") as key:
            key.write(line + "\n")
            key.flush()
            output = run("ssh-keygen", "-l", "-E", "sha256", "-f", key.name)
        result.add(output.split()[1])
    if not result:
        raise ValueError("GitHub returned no keys; refusing to remove all login keys")
    return sorted(result)


def main():
    root = Path(__file__).resolve().parents[2]
    os.chdir(root)
    username = run("nix", "eval", "--raw", "--file", "settings.nix", "githubName")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9-]{0,38}", username):
        raise ValueError("Invalid githubName")

    fetched = json.loads(
        run(
            "nix",
            "store",
            "prefetch-file",
            "--refresh",
            "--json",
            f"https://github.com/{username}.keys",
        )
    )
    current = {
        "hash": fetched["hash"],
        "fingerprints": fingerprints(
            Path(fetched["storePath"]).read_text(encoding="ascii")
        ),
    }
    target = root / "home/base/ssh-keys.json"
    previous = json.loads(target.read_text())
    changed = current != previous
    if output := os.environ.get("GITHUB_OUTPUT"):
        with open(output, "a") as stream:
            stream.write(f"changed={str(changed).lower()}\n")
    if not changed:
        print("SSH public keys are unchanged")
        return

    added = sorted(set(current["fingerprints"]) - set(previous["fingerprints"]))
    removed = sorted(set(previous["fingerprints"]) - set(current["fingerprints"]))
    body = [f"GitHub アカウント `{username}` の公開 SSH 鍵を更新します。", ""]
    for heading, values in [("追加", added), ("削除", removed)]:
        body.extend([f"### {heading}", ""])
        body.extend(f"- `{value}`" for value in values)
        if not values:
            body.append("なし")
        body.append("")
    body.append("鍵を確認してマージし、各端末で Home Manager を再適用してください。")
    body_path = (
        Path(os.environ.get("RUNNER_TEMP", tempfile.gettempdir())) / "ssh-keys-pr.md"
    )
    body_path.write_text("\n".join(body) + "\n")
    if output := os.environ.get("GITHUB_OUTPUT"):
        with open(output, "a") as stream:
            stream.write(f"body-path={body_path}\n")
    target.write_text(json.dumps(current, indent=2) + "\n")
    print(f"Updated SSH public keys; PR body: {body_path}")


if __name__ == "__main__":
    main()
