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


def update_settings(text, keys):
    # 他の設定やコメントを残し、sshKeys の値だけを置き換える。
    pattern = r"(?ms)^  sshKeys = \{\n.*?^  \};"
    matches = list(re.finditer(pattern, text))
    if len(matches) != 1:
        raise ValueError("Expected one sshKeys block in settings.nix")
    block = matches[0].group()
    for pattern, replacement in [
        (r'(?m)^    hash = "[^"\n]*";', f'    hash = "{keys["hash"]}";'),
        (
            r"(?ms)^    fingerprints = \[\n.*?^    \];",
            "    fingerprints = [\n"
            + "".join(f'      "{value}"\n' for value in keys["fingerprints"])
            + "    ];",
        ),
    ]:
        block, count = re.subn(pattern, lambda _, value=replacement: value, block)
        if count != 1:
            raise ValueError("Unexpected sshKeys format in settings.nix")
    match = matches[0]
    return text[: match.start()] + block + text[match.end() :]


def main():
    root = Path(__file__).resolve().parents[2]
    os.chdir(root)
    target = root / "settings.nix"
    original = target.read_text()
    settings = json.loads(run("nix", "eval", "--json", "--file", "settings.nix"))
    username = settings["githubName"]
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
    previous = settings["sshKeys"]
    changed = current != previous
    if output := os.environ.get("GITHUB_OUTPUT"):
        with open(output, "a") as stream:
            stream.write(f"changed={str(changed).lower()}\n")
    if not changed:
        print("SSH public keys are unchanged")
        return

    updated = update_settings(original, current)
    # 書き込む前に Nix として評価し、他の設定が変わっていないことを確認する。
    evaluated = json.loads(run("nix", "eval", "--json", "--expr", updated))
    if evaluated != settings | {"sshKeys": current}:
        raise ValueError("Unexpected changes outside sshKeys")

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
    if target.read_text() != original:
        raise ValueError(
            "settings.nix changed during the update; refusing to overwrite"
        )
    target.write_text(updated)
    print(f"Updated SSH public keys; PR body: {body_path}")


if __name__ == "__main__":
    main()
