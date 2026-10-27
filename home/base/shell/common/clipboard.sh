# SSH では OSC 52、ローカルではデスクトップのクリップボードを使用
pbcopy() {
  if [ -n "${SSH_CONNECTION:-}${SSH_CLIENT:-}" ] || { [ -z "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ] && [ -t 1 ]; }; then
    [ -t 1 ] || { printf 'pbcopy: a terminal is required for OSC 52\n' >&2; return 1; }
    printf '\033]52;c;%s\a' "$(base64 | tr -d '\r\n')"
  elif [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-copy >/dev/null 2>&1; then
    wl-copy
  elif [ -n "${DISPLAY:-}" ] && command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard
  else
    printf 'pbcopy: no usable clipboard found\n' >&2
    return 1
  fi
}

pbpaste() {
  if [ -n "${SSH_CONNECTION:-}${SSH_CLIENT:-}" ]; then
    printf 'pbpaste: reading the local clipboard over SSH is unsupported\n' >&2
    return 1
  elif [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-paste >/dev/null 2>&1; then
    wl-paste --no-newline
  elif [ -n "${DISPLAY:-}" ] && command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard -o
  else
    printf 'pbpaste: no usable clipboard found\n' >&2
    return 1
  fi
}
