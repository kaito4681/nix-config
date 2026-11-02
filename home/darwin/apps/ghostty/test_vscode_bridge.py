"""実行方法: python3 -m unittest discover -s ~/.config/ghostty -p 'test_*.py'"""

import json
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import threading
import unittest
from unittest.mock import patch

import vscode_bridge as bridge


class BridgeTests(unittest.TestCase):
    def request(self, payload):
        client, server = socket.socketpair()
        with client, server:
            def send():
                client.sendall(payload)
                client.shutdown(socket.SHUT_WR)
            sender = threading.Thread(target=send)
            sender.start()
            try:
                return bridge.receive_request(server, "secret")
            finally:
                sender.join(timeout=3)

    def test_authentication_and_schema(self):
        for request in ({"token": "wrong", "path": "/tmp"},
                        {"token": "日本語", "path": "/tmp"},
                        {"token": "secret", "path": "/tmp", "host": "other"},
                        {"token": "secret", "path": "--install-extension"},
                        {"token": "secret", "path": "/tmp\ncommand"},
                        {"token": "secret", "path": "/tmp\u0000command"},
                        {"token": "secret", "path": 42}, []):
            with self.subTest(request=request), self.assertRaises(ValueError):
                self.request(json.dumps(request).encode() + b"\n")
        with self.assertRaises(ValueError):
            self.request(b"x" * (bridge.MAX_REQUEST + 1))
        self.assertEqual(self.request(b'{"token":"secret","path":"/tmp"}\n'), "/tmp")

    def test_received_path_is_one_literal_argument(self):
        path = "/tmp/a ' $(touch /tmp/should-never-exist); -x"
        with patch.object(bridge.shutil, "which", return_value="/bin/code"), \
                patch.object(bridge.subprocess, "run") as run:
            bridge.open_code("my-server", path)
        self.assertEqual(run.call_args.args[0],
                         ["/bin/code", "--remote", "ssh-remote+my-server", "--", path])
        self.assertNotIn("shell", run.call_args.kwargs)

    def test_ssh_option_parser(self):
        cases = [(["server"], (0, True)),
                 (["-p", "2222", "-i", "/tmp/key file", "server"], (4, True)),
                 (["-tt", "--", "server"], (2, True)),
                 (["-T", "server"], (1, False)),
                 (["-N", "-L8080:localhost:80", "server"], (2, False)),
                 (["-W", "host:22", "server"], (2, False)),
                 (["-o", "ProxyCommand=ssh -W %h:%p jump", "server"], (2, True)),
                 (["-S", "/tmp/master", "server"], (2, False))]
        for args, expected in cases:
            with self.subTest(args=args):
                self.assertEqual(bridge.destination(args), expected)

    def test_session_uses_only_unix_sockets_and_cleans_up(self):
        bootstrap_calls = []

        def capture(args, **_):
            bootstrap_calls.append(args)
            return "/tmp/gv.ABCDEFGH" if len(bootstrap_calls) == 1 else ""

        with patch.object(bridge.sys.stdin, "isatty", return_value=True), \
                patch.object(bridge, "capture", side_effect=capture), \
                patch.object(bridge.subprocess, "call", return_value=17) as call, \
                patch.object(bridge.subprocess, "run") as run:
            self.assertEqual(bridge.ssh_session(["-tt", "--", "server"]), 17)
        args = call.call_args.args[0]
        forwarding = args[args.index("-R") + 1]
        remote, local = forwarding.split(":")
        self.assertEqual(remote, "/tmp/gv.ABCDEFGH/s")
        self.assertTrue(local.startswith("/tmp/gv-"))
        self.assertFalse(Path(local).parent.exists())
        self.assertNotIn("-tt", bootstrap_calls[0])
        self.assertIn("rm -f -- /tmp/gv.ABCDEFGH/s", bootstrap_calls[1][-1])
        self.assertEqual(run.call_args.args[0][-3:], ["-O", "exit", "server"])

    def test_remote_commands_and_tunnels_are_unchanged(self):
        for args in (["server", "ls"], ["-N", "server"], ["-T", "server"], ["-V"]):
            with self.subTest(args=args), \
                    patch.object(bridge.sys.stdin, "isatty", return_value=True), \
                    patch.object(bridge.os, "execv", side_effect=RuntimeError("exec")) as execute:
                with self.assertRaises(RuntimeError):
                    bridge.ssh_session(args)
                execute.assert_called_once_with(bridge.SSH, [bridge.SSH] + args)

    def test_real_zsh_code_function_and_rate_limit(self):
        plugin = Path(__file__).resolve().parents[1] / "sheldon/plugins/local/sync/ssh-terminal.plugin.zsh"
        if not plugin.exists():
            self.skipTest("remote shell plugin is not available")
        with tempfile.TemporaryDirectory(prefix="gv-test-", dir="/tmp") as directory:
            sock = directory + "/s"
            stop = threading.Event()
            listener = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            listener.bind(sock)
            listener.listen(4)
            opened = []
            with patch.object(bridge, "open_code", side_effect=lambda *args: opened.append(args)):
                thread = threading.Thread(target=bridge.serve,
                                          args=(listener, stop, "secret", "fixed-host"))
                thread.start()
                try:
                    env = dict(os.environ, SSH_CONNECTION="test", GHOSTTY_VSCODE_SOCKET=sock,
                               GHOSTTY_VSCODE_TOKEN="secret")
                    env.pop("VSCODE_IPC_HOOK_CLI", None)
                    target = directory + "/space ' $(echo injected); name"
                    args = ["/bin/zsh", "-fc", 'source "$1"; code "$2"', "zsh", str(plugin), target]
                    result = subprocess.run(args, env=env, capture_output=True, text=True, timeout=5)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(opened, [("fixed-host", target)])
                    result = subprocess.run(args, env=env, capture_output=True, text=True, timeout=5)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn("too frequent", result.stderr)
                    self.assertEqual(len(opened), 1)
                    env["GHOSTTY_VSCODE_TOKEN"] = "wrong"
                    result = subprocess.run(args, env=env, capture_output=True, text=True, timeout=5)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn("invalid request", result.stderr)
                finally:
                    stop.set()
                    thread.join(timeout=3)
                    listener.close()


if __name__ == "__main__":
    unittest.main()
