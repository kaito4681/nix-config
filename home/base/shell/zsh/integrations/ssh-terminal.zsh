if [[ -o interactive && -t 0 ]]; then
    { stty -ixon < /dev/tty } 2>/dev/null
fi

# WezTerm の新しいタブで実行するコマンドを入力欄に設定
if [[ -n "$WEZTERM_PREFILL" ]]; then
    [[ -o interactive ]] && print -z -- "$WEZTERM_PREFILL"
    unset WEZTERM_PREFILL
fi

if [[ -n "$SSH_CONNECTION" || -n "$SSH_CLIENT" ]]; then
    # tmux の入れ子に合わせて制御シーケンスを送信（allow-passthrough が必要）
    function _wezterm_send() {
        local esc=$'\e'
        local once="${esc}Ptmux;${1//$esc/$esc$esc}$esc\\"
        local twice="${esc}Ptmux;${once//$esc/$esc$esc}$esc\\"
        printf '%s' "$1" "$once" "$twice"
    }

    # 現在のディレクトリを WezTerm に通知
    function _wezterm_report_cwd() {
        emulate -L zsh
        setopt extended_glob
        local LC_ALL=C
        local encoded="${PWD//(#m)[^A-Za-z0-9\/._~-]/%${(l:2::0:)$(( [##16] #MATCH ))}}"
        _wezterm_send $'\e]7;file://'"$HOST$encoded"$'\a'
    }
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd _wezterm_report_cwd

    # サーバー上のパスを接続元の VS Code で開く
    function code() {
        emulate -L zsh
        zmodload -F zsh/datetime p:EPOCHREALTIME
        if [[ -n "$VSCODE_IPC_HOOK_CLI" ]]; then
            command code "$@"
            return $?
        fi

        local remote_host="${WEZTERM_VSCODE_SSH_HOST:-}"
        if [[ "$remote_host" == -* || "$remote_host" == *[^a-zA-Z0-9_.@:+-]* ]]; then
            print -u2 'code: invalid WEZTERM_VSCODE_SSH_HOST'
            return 1
        fi
        if (( $# > 1 )) || [[ "${1:-.}" == -* ]]; then
            print -u2 'Usage: code [file-or-directory] (WezTerm remote bridge)'
            return 1
        fi
        local target="${1:-.}"
        target="${target:a}"
        if [[ "$target" == *$'\t'* || "$target" == *$'\r'* || "$target" == *$'\n'* ]]; then
            print -u2 'code: paths containing tabs or newlines are unsupported'
            return 1
        fi
        local id="${EPOCHREALTIME//./}$RANDOM"
        local payload
        payload=$(printf '%s\t%s\t%s' "$id" "$remote_host" "$target" | base64 | tr -d '\r\n') || return 1
        _wezterm_send $'\e]1337;SetUserVar=OPEN_VSCODE='"$payload"$'\a'
    }
fi
