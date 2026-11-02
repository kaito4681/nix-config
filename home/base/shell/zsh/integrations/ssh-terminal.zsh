if [[ -o interactive && -t 0 ]]; then
    { stty -ixon < /dev/tty } 2>/dev/null
fi

# Ghostty の SSH 接続で、SSH 先のパスを手元の VS Code で開く
if [[ -n "$SSH_CONNECTION" || -n "$SSH_CLIENT" ]]; then
    function code() {
        emulate -L zsh
        if [[ -n "$VSCODE_IPC_HOOK_CLI" ]]; then
            command code "$@"
            return $?
        fi
        if [[ -z "$GHOSTTY_VSCODE_SOCKET" ]]; then
            print -u2 'code: connect with ssh from Ghostty to open paths in local VS Code'
            return 1
        fi
        if (( $# > 1 )) || [[ "${1:-.}" == -* ]]; then
            print -u2 'Usage: code [file-or-directory]'
            return 1
        fi
        command python3 - "${${1:-.}:a}" <<'PYTHON'
import json
import os
import socket
import sys

try:
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.settimeout(20)
        client.connect(os.environ["GHOSTTY_VSCODE_SOCKET"])
        request = {"token": os.environ["GHOSTTY_VSCODE_TOKEN"], "path": sys.argv[1]}
        client.sendall(json.dumps(request).encode() + b"\n")
        response = bytearray()
        while len(response) < 4096 and not response.endswith(b"\n"):
            chunk = client.recv(4096 - len(response))
            if not chunk:
                break
            response.extend(chunk)
        if response != b"ok\n":
            raise ValueError(response.decode(errors="replace").strip() or "bridge disconnected")
except (KeyError, OSError, ValueError) as error:
    print("code: " + str(error), file=sys.stderr)
    sys.exit(1)
PYTHON
    }
fi
