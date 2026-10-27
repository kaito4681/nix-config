# SSH 設定から接続先の補完候補を取得
__ssh_completion_hosts() {
    emulate -L zsh
    setopt extended_glob null_glob

    local -a pending hosts matches
    local -A seen_files
    local file line key value pattern host

    pending=("$HOME/.ssh/config")

    while (( $#pending )); do
        file="$pending[1]"
        pending=("${pending[@]:1}")
        [[ -n "$file" && -r "$file" && -z "${seen_files[$file]}" ]] || continue
        seen_files[$file]=1

        while IFS= read -r line || [[ -n "$line" ]]; do
            line="${line%%\#*}"
            line="${line##[[:space:]]#}"
            line="${line%%[[:space:]]#}"
            [[ -n "${line//[[:space:]]/}" ]] || continue

            key="${line%%[[:space:]=]*}"
            value="${line#"$key"}"
            value="${value##[[:space:]=]#}"
            value="${value%%[[:space:]]#}"

            case "${key:l}" in
                include)
                    for pattern in ${(z)value}; do
                        [[ "$pattern" = /* || "$pattern" = "~"* ]] || pattern="${file:h}/$pattern"
                        matches=(${~pattern}(N))
                        pending+=("${matches[@]}")
                    done
                    ;;
                host)
                    for host in ${(z)value}; do
                        [[ "$host" == *[\*\?]* ]] && continue
                        hosts+=("$host")
                    done
                    ;;
            esac
        done < "$file"
    done

    print -l ${(ou)hosts}
}

_ssh_hosts() {
    local -a hosts
    hosts=("${(@f)$(__ssh_completion_hosts)}")
    (( $#hosts )) || return 1

    compadd -M 'm:{a-zA-Z}={A-Za-z} r:|.=* r:|=*' "$@" -- "${hosts[@]}"
}

__ssh_uri_escape_path() {
    emulate -L zsh

    local path="$1"
    path="${path//\%/%25}"
    path="${path// /%20}"
    path="${path//\#/%23}"
    path="${path//\?/%3F}"
    print -r -- "$path"
}

__ssh_remote_home() {
    emulate -L zsh

    local host="$1"
    local home
    home="$(ssh -o BatchMode=yes -o ConnectTimeout=3 "$host" 'printf %s "$HOME"' 2>/dev/null)" || return 1
    [[ "$home" == /* ]] || return 1
    print -r -- "$home"
}

__ssh_vscode_remote_command() {
    emulate -L zsh

    local host="$1"
    local path="$2"
    local help

    help="$(code --help 2>/dev/null)"
    if [[ "$help" == *"--remote"* ]]; then
        print -r -- "code --remote ${(q)${:-ssh-remote+$host}} ${(q)path}"
    else
        path="$(__ssh_uri_escape_path "$path")"
        print -r -- "code --folder-uri ${(q)${:-vscode-remote://ssh-remote+$host$path}}"
    fi
}

__ssh_fzf_select_host() {
    emulate -L zsh

    if ! command -v fzf >/dev/null 2>&1; then
        print -u2 -- "fzf is not installed"
        return 1
    fi

    { stty -ixon < /dev/tty } 2>/dev/null

    local mode_file="${TMPDIR:-/tmp}/ssh-fzf-mode.$$.$RANDOM"
    print -r -- "ssh" > "$mode_file"

    local to_vscode="execute-silent(printf vscode > ${(q)mode_file})+change-prompt([VSCode Remote] > )+change-header(CTRL-S: close	| ENTER: Open in VS Code Remote SSH)"
    local cycle_cmd="transform:echo {fzf:prompt} | grep -q 'VSCode' && echo abort || echo \"$to_vscode\""

    local host mode
    host=$(__ssh_completion_hosts | fzf \
        --prompt="[SSH] > " \
        --header="CTRL-S: VSCode Remote	| ENTER: SSH connect" \
        --bind "ctrl-s:$cycle_cmd" \
        --exit-0)

    if [[ -r "$mode_file" ]]; then
        mode="$(<"$mode_file")"
        command rm -f "$mode_file" 2>/dev/null
    else
        mode="ssh"
    fi

    [[ -n "$host" ]] || return 1
    print -r -- "$mode:$host"
}

__ssh_fzf_widget() {
    emulate -L zsh

    local selection mode host
    selection="$(__ssh_fzf_select_host)" || {
        zle reset-prompt
        return 0
    }

    mode="${selection%%:*}"
    host="${selection#*:}"

    case "$mode" in
        vscode)
            local remote_home
            remote_home="$(__ssh_remote_home "$host")" || remote_home="/"
            BUFFER="$(__ssh_vscode_remote_command "$host" "$remote_home")"
            ;;
        *)
            if [[ -z "${BUFFER//[[:space:]]/}" ]]; then
                BUFFER="ssh ${(q)host}"
            elif [[ "$BUFFER" == ssh[[:space:]]* ]]; then
                [[ -z "$LBUFFER" || "$LBUFFER[-1]" == [[:space:]] ]] || LBUFFER+=" "
                LBUFFER+="${(q)host}"
            else
                BUFFER="ssh ${(q)host}"
            fi
            ;;
    esac

    CURSOR=${#BUFFER}
    zle reset-prompt
    zle redisplay
    zle accept-line
}

if [[ -o interactive ]]; then
    { stty -ixon < /dev/tty } 2>/dev/null
    zle -N __ssh_fzf_widget
    bindkey -M emacs '^S' __ssh_fzf_widget
    bindkey -M viins '^S' __ssh_fzf_widget
fi

zstyle -e ':completion:*:*:ssh:*:hosts' hosts 'reply=("${(@f)$(__ssh_completion_hosts)}")'
zstyle ':completion:*:*:ssh:*' tag-order hosts
zstyle -e ':completion:*:*:scp:*:hosts' hosts 'reply=("${(@f)$(__ssh_completion_hosts)}")'
zstyle -e ':completion:*:*:sftp:*:hosts' hosts 'reply=("${(@f)$(__ssh_completion_hosts)}")'
zstyle -e ':completion:*:*:rsync:*:hosts' hosts 'reply=("${(@f)$(__ssh_completion_hosts)}")'
