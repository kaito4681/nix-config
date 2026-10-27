# SSH 接続元で URL を開く
open() {
  if [ -z "${SSH_CONNECTION:-}${SSH_CLIENT:-}${VSCODE_IPC_HOOK_CLI:-}" ]; then
    command xdg-open "$@"
    return $?
  fi

  if [ "$#" -ne 1 ]; then
    printf 'Usage: open <http-or-https-url> (remote session)\n' >&2
    return 1
  fi
  case "$1" in
    *[[:cntrl:]]*)
      printf 'open: URL must not contain control characters\n' >&2
      return 1
      ;;
    http://?*|https://?*) ;;
    *)
      printf 'open: remote sessions support HTTP(S) URLs only\n' >&2
      return 1
      ;;
  esac

  # VS Code Remote のブラウザ連携
  if [ -n "${VSCODE_IPC_HOOK_CLI:-}" ] && [ -n "${BROWSER:-}" ] && [ -x "$BROWSER" ]; then
    "$BROWSER" "$1"
    return $?
  fi

  # クリック可能な URL を表示
  # リンクの表示名にも URL を使用
  if [ -t 1 ] && [ "${TERM:-dumb}" != dumb ]; then
    printf '\033]8;;%s\033\\%s\033]8;;\033\\\n' "$1" "$1"
  else
    printf '%s\n' "$1"
  fi
}
