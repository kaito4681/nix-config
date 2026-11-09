import hashlib
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import update


class ReleaseUpdaterTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.pin = Path(self.temp.name) / "release.json"
        self.original = '{"version":"0.1.7","hashes":{}}\n'
        self.pin.write_text(self.original)
        self.manifest = Path(self.temp.name) / "packages.json"
        self.manifest.write_text(json.dumps({"t3code": {
            "repository": "pingdotgg/t3code", "pin": "release.json",
            "assets": {"aarch64-darwin": "T3-Code-{version}-arm64.zip", "x86_64-linux": "t3-{version}-linux-x64.tar.gz"},
            "checks": [{"runner": "ubuntu-24.04", "verify": "ci/pkgs/verify/t3code.sh"}],
        }}))
        self.payload = b"official release fixture"
        self.release = {
            "tag_name": "v0.1.8", "draft": False, "prerelease": False,
            "assets": [self.asset("T3-Code-0.1.8-arm64.zip"), self.asset("t3-0.1.8-linux-x64.tar.gz")],
        }

    def asset(self, name):
        return {
            "name": name, "size": len(self.payload),
            "digest": "sha256:" + hashlib.sha256(self.payload).hexdigest(),
            "browser_download_url": f"https://github.com/pingdotgg/t3code/releases/download/v0.1.8/{name}",
        }

    def run_updater(self, downloads=2):
        responses = [io.BytesIO(json.dumps(self.release).encode())]
        responses += [io.BytesIO(self.payload) for _ in range(downloads)]
        with patch.object(update, "ROOT", Path(self.temp.name)), patch.object(update, "MANIFEST", self.manifest), patch.object(update, "output"), patch.object(
            update.urllib.request, "urlopen", side_effect=responses
        ) as request:
            update.main()
            return request.call_count

    def test_verified_update_changes_both_hashes(self):
        self.assertEqual(self.run_updater(), 3)
        result = json.loads(self.pin.read_text())
        self.assertEqual(result["version"], "0.1.8")
        self.assertEqual(set(result["hashes"]), {"aarch64-darwin", "x86_64-linux"})
        self.assertTrue(all(value.startswith("sha256-") for value in result["hashes"].values()))

    def test_same_or_older_version_does_not_download(self):
        for tag in ("v0.1.7", "v0.1.6"):
            self.release["tag_name"] = tag
            self.assertEqual(self.run_updater(downloads=0), 1)
            self.assertEqual(self.pin.read_text(), self.original)

    def test_second_asset_mismatch_leaves_pin_unchanged(self):
        self.release["assets"][1]["digest"] = "sha256:" + "0" * 64
        with self.assertRaises(ValueError):
            self.run_updater()
        self.assertEqual(self.pin.read_text(), self.original)

    def test_missing_asset_leaves_pin_unchanged(self):
        self.release["assets"].pop()
        with self.assertRaises(KeyError):
            self.run_updater()
        self.assertEqual(self.pin.read_text(), self.original)

    def test_missing_digest_and_wrong_size_fail(self):
        for field, value in (("digest", None), ("size", 0)):
            self.release["assets"][0] = self.asset("T3-Code-0.1.8-arm64.zip")
            self.release["assets"][0][field] = value
            with self.assertRaises((TypeError, ValueError)):
                self.run_updater()
            self.assertEqual(self.pin.read_text(), self.original)

    def test_multiple_packages_are_atomic_and_generate_check_matrix(self):
        registry = json.loads(self.manifest.read_text())
        other = Path(self.temp.name) / "other.json"
        registry["another"] = {**registry["t3code"], "pin": "other.json"}
        self.manifest.write_text(json.dumps(registry))
        for fail_second in (True, False):
            self.pin.write_text(self.original)
            other.write_text(self.original)
            second = json.loads(json.dumps(self.release))
            if fail_second:
                second["assets"][1]["digest"] = "sha256:" + "0" * 64
            responses = []
            for release in (self.release, second):
                responses.extend([io.BytesIO(json.dumps(release).encode()),
                                  io.BytesIO(self.payload), io.BytesIO(self.payload)])
            with patch.object(update, "ROOT", Path(self.temp.name)), patch.object(
                update, "MANIFEST", self.manifest
            ), patch.object(update, "output") as output, patch.object(
                update.urllib.request, "urlopen", side_effect=responses
            ):
                if fail_second:
                    with self.assertRaises(ValueError):
                        update.main()
                    self.assertEqual(self.pin.read_text(), self.original)
                    self.assertEqual(other.read_text(), self.original)
                else:
                    update.main()
                    self.assertEqual(json.loads(other.read_text())["version"], "0.1.8")
                    emitted = dict(call.args for call in output.call_args_list)
                    self.assertEqual(emitted["paths"], "release.json,other.json")
                    checks = json.loads(emitted["matrix"])["include"]
                    self.assertEqual([check["package"] for check in checks], ["t3code", "another"])

    def test_prerelease_draft_and_invalid_tags_fail(self):
        for tag in ("v0.1.8-nightly.1", "bad", "v01.2.3"):
            with self.assertRaises(ValueError):
                update.version_tuple(tag)
        for flag in ("prerelease", "draft"):
            self.release[flag] = True
            with self.assertRaises(ValueError):
                self.run_updater(downloads=0)
            self.release[flag] = False
            self.assertEqual(self.pin.read_text(), self.original)


if __name__ == "__main__":
    unittest.main()
