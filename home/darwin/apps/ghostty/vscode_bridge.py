#!/usr/bin/env python3
"""Ghostty から VS Code を開くブリッジと、SSH セッションごとの Unix ソケット中継（標準ライブラリのみ）。"""

import ctypes
import json
import os
from pathlib import Path
import re
import secrets
import shlex
import shutil
import socket
import struct
import subprocess
import sys
import tempfile
import threading
import time


SSH = "/usr/bin/ssh"
ARGUMENT_OPTIONS = set("BbcDEeFIiJLlmOoPpQRSWw")
HOST = re.compile(r"[A-Za-z0-9_][A-Za-z0-9_.@:+-]*\Z")
REMOTE_DIR = re.compile(r"/tmp/gv\.[A-Za-z0-9]+\Z")
REMOTE_FORWARD = re.compile(r"(/tmp/gv\.[A-Za-z0-9]+/s):")
MAX_REQUEST = 16384

# Linux の /proc から、最近入力のあった pty の前面プロセスのディレクトリを推定する。
# 最近使われた pty のうち tmux 内側のものを優先する。リモートのシェルにフックは要らない。
# $sock があれば、その中継の環境変数を持つプロセスがいる pty に絞り、ほかの接続と
# 取り違えないようにする。該当する pty がなければ全体から推定する。前面が tmux の
# クライアントなら、tmux にそのクライアントが表示しているペインのパスを聞く。
REMOTE_CWD = r"""
{ [ -n "$sock" ] && grep -lzxF "GHOSTTY_VSCODE_SOCKET=$sock" /proc/[0-9]*/environ 2>/dev/null | sed -n 's|^/proc/\([0-9]*\)/environ$|P \1|p'
  stat -c 'S %X %U %n' /dev/pts/[0-9]*; ps -eo pid=,ppid=,sid=,tpgid=,tty=,comm=; } | awk -v me="$(id -un)" -v self="$(tty)" '
$1 == "P" { mine[$2] = 1; next }
$1 == "S" { if ($3 == me && $4 != self) { t = $4; sub("^/dev/", "", t); atime[t] = $2 }; next }
{ ppid[$1] = $2; comm[$1] = $6; if ($5 ~ /^pts\//) { fg[$5] = $4; if ($1 == $3) leader[$5] = $1; if ($1 in mine) { owned[$5] = 1; scoped = 1 } } }
END {
  for (t in atime) if (fg[t] > 0 && (!scoped || t in owned) && atime[t] > latest) latest = atime[t]
  for (t in atime) {
    if (fg[t] <= 0 || (scoped && !(t in owned)) || atime[t] <= latest - 8) continue
    outer = comm[ppid[leader[t]]] ~ /^sshd/
    if (best == "" || (bestOuter && !outer) || (bestOuter == outer && atime[t] > atime[best])) { best = t; bestOuter = outer }
  }
  if (best != "") print fg[best], best, (comm[fg[best]] ~ /^tmux/ ? "tmux" : "-")
}' | { read -r pid tty kind || exit
  if [ "$kind" = tmux ] && path=$(tmux display-message -p -c "/dev/$tty" '#{pane_current_path}' 2>/dev/null) && [ -n "$path" ]; then
    printf '%s\n' "$path"
  else
    readlink "/proc/$pid/cwd"
  fi; }
"""


def capture(args, timeout=15):
    return subprocess.run(args, check=True, capture_output=True, text=True,
                          timeout=timeout).stdout.rstrip("\r\n")


def destination(args):
    """接続先の位置と、通常の対話的な SSH かどうかを返す。"""
    index = 0
    interactive = True
    while index < len(args):
        arg = args[index]
        if arg == "--":
            return index + 1, interactive
        if not arg.startswith("-") or arg == "-":
            return index, interactive
        for offset, option in enumerate(arg[1:], 1):
            if option in "TNnfGWQOVMS":
                interactive = False
            if option in ARGUMENT_OPTIONS:
                if offset == len(arg) - 1:
                    index += 1
                break
        index += 1
    return index, False


def valid_path(path):
    return (isinstance(path, str) and path.startswith("/")
            and len(path.encode("utf-8")) <= 8192
            and not any(ord(char) < 32 or ord(char) == 127 for char in path))


def open_code(host, path):
    if not valid_path(path) or (host is not None and not HOST.fullmatch(host)):
        raise ValueError("invalid VS Code host or absolute path")
    executable = shutil.which("code")
    if not executable:
        raise ValueError("code CLI not found in PATH")
    args = [executable]
    if host is not None:
        args += ["--remote", "ssh-remote+" + host]
    # 受け取ったデータをシェルに埋め込んだり、追加の CLI フラグとして受け付けたりしない。
    subprocess.run(args + ["--", path], check=True, timeout=15,
                   stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                   stderr=subprocess.DEVNULL)


def receive_request(connection, token):
    connection.settimeout(2)
    data = bytearray()
    while len(data) <= MAX_REQUEST:
        chunk = connection.recv(min(4096, MAX_REQUEST + 1 - len(data)))
        if not chunk:
            break
        data.extend(chunk)
        if b"\n" in chunk:
            break
    if len(data) > MAX_REQUEST:
        raise ValueError("request too large")
    request = json.loads(data)
    if (not isinstance(request, dict) or set(request) != {"token", "path"}
            or not isinstance(request["token"], str)
            or not secrets.compare_digest(request["token"].encode(), token.encode())
            or not valid_path(request["path"])):
        raise ValueError("invalid request")
    return request["path"]


def serve(listener, stop, token, host):
    last_open = 0.0
    listener.settimeout(0.2)
    while not stop.is_set():
        try:
            connection, _ = listener.accept()
        except socket.timeout:
            continue
        with connection:
            try:
                path = receive_request(connection, token)
                now = time.monotonic()
                if now - last_open < 1:
                    raise ValueError("requests too frequent; retry in a second")
                last_open = now
                open_code(host, path)
                connection.sendall(b"ok\n")
            except (ValueError, OSError, RecursionError, subprocess.SubprocessError) as error:
                try:
                    connection.sendall(("error: " + str(error) + "\n").encode())
                except OSError:
                    pass


def ssh_session(args):
    index, interactive = destination(args)
    if (not interactive or index != len(args) - 1
            or not HOST.fullmatch(args[index]) or not sys.stdin.isatty()):
        os.execv(SSH, [SSH] + args)
    host = args[index]
    options = args[:index]
    if options[-1:] == ["--"]:
        options = options[:-1]
    # 元のコマンドに -t/-tt があっても、準備と後片付けは非対話で実行する。
    # ほかの SSH オプションの引数はそのまま残す。
    query_options = []
    cursor = 0
    while cursor < len(options):
        arg = options[cursor]
        filtered = "-"
        for offset, option in enumerate(arg[1:], 1):
            if option in ARGUMENT_OPTIONS:
                filtered += arg[offset:]
                if offset == len(arg) - 1:
                    query_options += [filtered, options[cursor + 1]]
                    cursor += 1
                else:
                    query_options.append(filtered)
                break
            if option not in "tT":
                filtered += option
        else:
            if filtered != "-":
                query_options.append(filtered)
        cursor += 1
    # /tmp を使って Unix ソケットのパスを macOS の 104 バイト制限に収める。mkdtemp は
    # アトミックでモード 0700。どちらのマシンでも TCP の待ち受けは作らない。
    with tempfile.TemporaryDirectory(prefix="gv-", dir="/tmp") as directory:
        token = secrets.token_hex(32)
        local_socket = directory + "/s"
        control = directory + "/m"
        shared = [SSH, "-o", "ControlMaster=auto", "-o", "ControlPersist=30s",
                  "-o", "ControlPath=" + control]
        remote_directory = None
        stop = threading.Event()
        listener = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        thread = None
        try:
            listener.bind(local_socket)
            os.chmod(local_socket, 0o600)
            listener.listen(4)
            # 準備にはセッションと同じ認証済みの接続を使う。
            # この補助的な接続ではユーザー設定のフォワードを繰り返さない。
            bootstrap = ("command -v python3 >/dev/null || { "
                         "echo 'ghostty bridge: remote python3 is required' >&2; exit 1; }; "
                         "umask 077; mktemp -d /tmp/gv.XXXXXXXX")
            try:
                result = capture(shared + ["-o", "ClearAllForwardings=yes", "-T"]
                                 + query_options + [host, bootstrap], timeout=120)
            except subprocess.CalledProcessError as error:
                raise ValueError(error.stderr.strip() or "SSH bridge bootstrap failed") from error
            remote_directory = result.splitlines()[-1] if result else ""
            if not REMOTE_DIR.fullmatch(remote_directory):
                raise ValueError("could not create private remote socket directory")
            remote_socket = remote_directory + "/s"
            thread = threading.Thread(target=serve,
                                      args=(listener, stop, token, host), daemon=True)
            thread.start()
            # リモートが選べるのはパスだけで、VS Code で開くホストは選べない。
            script = ("export GHOSTTY_VSCODE_SOCKET=" + shlex.quote(remote_socket)
                      + " GHOSTTY_VSCODE_TOKEN=" + shlex.quote(token)
                      + '; "$SHELL" -l')
            command = "sh -c " + shlex.quote(script)
            return subprocess.call(shared + ["-o", "ExitOnForwardFailure=yes"]
                                   + options + ["-t", "-R", remote_socket + ":" + local_socket,
                                                host, command])
        finally:
            stop.set()
            if thread:
                thread.join(timeout=18)
            listener.close()
            if remote_directory and REMOTE_DIR.fullmatch(remote_directory):
                cleanup = ("rm -f -- " + shlex.quote(remote_directory + "/s")
                           + "; rmdir -- " + shlex.quote(remote_directory))
                try:
                    capture(shared + ["-o", "BatchMode=yes", "-o", "ClearAllForwardings=yes",
                                      "-T"] + query_options + [host, cleanup], timeout=5)
                except (OSError, subprocess.SubprocessError):
                    pass
            # セッションごとのマスター接続を中継の待ち受けより長く残さない。
            try:
                subprocess.run([SSH, "-S", control, "-O", "exit", host],
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                               timeout=5, check=False)
            except (OSError, subprocess.SubprocessError):
                pass


def process_args(pid):
    if sys.platform != "darwin":
        return Path(f"/proc/{pid}/cmdline").read_bytes().rstrip(b"\0").decode().split("\0")
    # ps の整形済みコマンド列と違い、KERN_PROCARGS2 は argv の区切りを保つ。
    # 鍵ファイルや ProxyCommand の値に含まれる空白も崩れない。
    libc = ctypes.CDLL(None, use_errno=True)
    mib = (ctypes.c_int * 3)(1, 49, pid)  # CTL_KERN, KERN_PROCARGS2
    size = ctypes.c_size_t(os.sysconf("SC_ARG_MAX"))
    buffer = ctypes.create_string_buffer(size.value)
    if libc.sysctl(mib, 3, buffer, ctypes.byref(size), None, 0) != 0:
        raise OSError(ctypes.get_errno(), "cannot read process argv")
    raw = buffer.raw[:size.value]
    count = struct.unpack_from("i", raw)[0]
    start = raw.index(b"\0", 4)
    while start < len(raw) and raw[start] == 0:
        start += 1
    return [part.decode("utf-8", "surrogateescape")
            for part in raw[start:].split(b"\0")[:count]]


def process_table():
    result = {}
    for line in capture(["/bin/ps", "-axo", "pid=,ppid=,comm="]).splitlines():
        fields = line.split(None, 2)
        if len(fields) == 3:
            result[int(fields[0])] = (int(fields[1]), fields[2])
    return result


def find_ssh(pid, processes):
    visited = set()

    def visit(current):
        if current in visited:
            return None
        visited.add(current)
        if Path(processes.get(current, (0, ""))[1]).name == "ssh":
            try:
                argv = process_args(current)
                index, _ = destination(argv[1:])
                # -T を使うバックグラウンド接続は除外する。
                if index < len(argv) - 1 and "-T" not in argv[1:index + 1]:
                    return argv[1:index + 2]
            except OSError:
                pass
        for child, (parent, _) in processes.items():
            if parent == current:
                found = visit(child)
                if found:
                    return found
        return None

    return visit(pid)


def bridge_socket(command):
    """中継を通した接続なら、SSH 先に転送しているソケットのパスを返す。"""
    for previous, arg in zip([""] + command, command):
        value = arg if previous == "-R" else arg[2:] if arg.startswith("-R") else ""
        match = REMOTE_FORWARD.match(value)
        if match:
            return match.group(1)
    return ""


def multiplexer_pid(pid, tty, processes):
    if Path(processes.get(pid, (0, ""))[1]).name != "tmux":
        return pid
    argv = process_args(pid)
    command = [argv[0]]
    for index, arg in enumerate(argv[1:], 1):
        if arg in ("-L", "-S") and index + 1 < len(argv):
            command += [arg, argv[index + 1]]
        elif arg.startswith(("-L", "-S")) and len(arg) > 2:
            command += [arg]
    lines = capture(command + ["list-clients", "-F", "#{client_tty}\t#{pane_pid}"])
    for line in lines.splitlines():
        client_tty, pane_pid = line.split("\t", 1)
        if client_tty == tty:
            return int(pane_pid)
    raise ValueError("could not determine the active tmux pane")


def open_current():
    script = '''tell application "Ghostty"
    set t to focused terminal of selected tab of front window
    return (pid of t as text) & linefeed & (tty of t)
end tell'''
    fields = capture(["/usr/bin/osascript", "-e", script]).split("\n", 1)
    pid, tty = int(fields[0]), fields[1]
    processes = process_table()
    pid = multiplexer_pid(pid, tty, processes)
    command = find_ssh(pid, processes)
    if command:
        host = command[-1]
        # この問い合わせではフォワードの待ち受けを開かない。パスワードを尋ねたり、
        # SSH 切断後に古い OSC 7 のディレクトリを使ったりもしない。
        script = "sock=" + shlex.quote(bridge_socket(command)) + REMOTE_CWD
        path = capture([SSH, "-o", "BatchMode=yes", "-o", "ClearAllForwardings=yes"]
                       + command[:-1] + ["-T", host, script])
        open_code(host, path)
    else:
        cwd = capture(["/usr/sbin/lsof", "-a", "-p", str(pid), "-d", "cwd", "-Fn"])
        paths = [line[1:] for line in cwd.splitlines() if line.startswith("n/")]
        if len(paths) != 1:
            raise ValueError("could not determine the local process directory")
        open_code(None, paths[0])


def main():
    try:
        if sys.argv[1:2] == ["ssh"]:
            return ssh_session(sys.argv[2:])
        if sys.argv[1:] == ["current"]:
            open_current()
            return 0
        raise ValueError("usage: vscode_bridge.py current | ssh [ssh arguments]")
    except (ValueError, OSError, subprocess.SubprocessError, KeyError) as error:
        print("Ghostty VS Code: " + str(error), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
