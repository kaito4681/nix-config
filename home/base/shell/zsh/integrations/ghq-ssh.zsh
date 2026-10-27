# ローカル・SSH 接続先の ghq リポジトリを fzf で検索

# 再読み込み用にスクリプトのパスを保存
__GHQ_SSH_PLUGIN_PATH="${0:A}"

# リポジトリごとの最終更新時刻とパスを取得
__GHQ_SSH_LIST_SCRIPT='
use strict;
use warnings;

my $ghq = shift // q{ghq};
open my $list, q{-|}, $ghq, qw(list --full-path) or exit 1;
chomp(my @repos = <$list>);
close $list;
exit 0 unless @repos;

my %is_repo = map { $_ => 1 } @repos;
my %mtime;
sub newer {
    my ($repo, $file) = @_;
    my $m = (lstat $file)[9] // return;
    $mtime{$repo} = $m if $m > ($mtime{$repo} // 0);
}

local $/ = qq{\0};
if (grep { -x qq{$_/rg} } split /:/, $ENV{PATH} // q{}) {
    open my $rg, q{-|}, qw(rg --files --hidden -g !.git -0 --), @repos or exit 1;
    while (my $file = <$rg>) {
        chomp $file;
        # ファイルが属するリポジトリを検索
        my $dir = $file;
        while ($dir =~ s{/[^/]*\z}{} && length $dir) {
            if ($is_repo{$dir}) { newer($dir, $file); last }
        }
    }
} else {
    for my $repo (@repos) {
        open my $git, q{-|}, qw(git -C), $repo, qw(ls-files -z --cached --others --exclude-standard) or next;
        while (my $file = <$git>) { chomp $file; newer($repo, qq{$repo/$file}) }
    }
}

print +($mtime{$_} // 0), qq{\t$_\n} for @repos;
'

# 更新日時の新しい順に並べ、表示用の日時を追加
__ghq_format() {
    emulate -L zsh
    zmodload -F zsh/datetime b:strftime p:EPOCHSECONDS

    local type host epoch repo when rel display
    local -i diff
    sort -t $'\t' -k3,3nr | while IFS=$'\t' read -r type host epoch repo; do
        if (( epoch > 0 )); then
            strftime -s when '%Y-%m-%d %H:%M' "$epoch"
            diff=$(( EPOCHSECONDS - epoch ))
            if   (( diff < 60 ));       then rel="just now"
            elif (( diff < 3600 ));     then rel="$(( diff / 60 ))m ago"
            elif (( diff < 86400 ));    then rel="$(( diff / 3600 ))h ago"
            elif (( diff < 2592000 ));  then rel="$(( diff / 86400 ))d ago"
            elif (( diff < 31536000 )); then rel="$(( diff / 2592000 ))mo ago"
            else                             rel="$(( diff / 31536000 ))y ago"
            fi
        else
            when="----------------"
            rel="-"
        fi
        rel="${(r:10:)rel}"
        display="${repo/#$HOME/~}"
        [[ "$type" == remote ]] && display="$host:$repo"
        print -r -- "$type"$'\t'"$host"$'\t'"$repo"$'\t'$'\e[90m'"$when $rel"$'\e[0m'$'\t'"$display"
    done
}

# ローカルのリポジトリ検索
__ghq_search_local() {
    print -r -- "$__GHQ_SSH_LIST_SCRIPT" | perl - ghq 2>/dev/null | sed $'s/^/local\t-\t/' | __ghq_format
}

# 環境変数または SSH 設定から接続先を取得
__ghq_remote_hosts() {
    emulate -L zsh

    if [[ -n "${GHQ_REMOTE_HOSTS}" ]]; then
        print -l ${(s: :)GHQ_REMOTE_HOSTS}
        return
    fi

    if (( $+functions[__ssh_completion_hosts] )); then
        __ssh_completion_hosts
        return
    fi

    print -r -- "error:GHQ_REMOTE_HOSTS_not_set"
}

# SSH 接続先のリポジトリ検索
__ghq_search_remote() {
    local -a hosts
    hosts=("${(@f)$(__ghq_remote_hosts)}")

    if (( ! $#hosts )) || [[ "${hosts[1]}" == error:* ]]; then
        print -r -- $'error\t-\t-\t\t\e[31mGHQ_REMOTE_HOSTS is not set\e[0m'
        return
    fi

    {
    local pids=()
    local host
    for host in "${hosts[@]}"; do
        local ghq_path="ghq"
        local var_name="GHQ_PATH_${host}"
        local normalized_var_name="GHQ_PATH_${host//[^[:alnum:]_]/_}"
        if [[ -n "${(P)var_name}" ]]; then
            ghq_path="${(P)var_name}"
        elif [[ "$normalized_var_name" != "$var_name" && -n "${(P)normalized_var_name}" ]]; then
            ghq_path="${(P)normalized_var_name}"
        fi
        print -r -- "$__GHQ_SSH_LIST_SCRIPT" | ssh -q "$host" perl - "$ghq_path" 2>/dev/null | sed $'s/^/remote\t'"$host"$'\t/' &
        pids+=($!)
    done
    wait "${pids[@]}" 2>/dev/null
    } | __ghq_format
}

# 検索画面の表示
__ghq_search() {
    local to_local="change-prompt([Local] > )+change-header(CTRL+R: to Remote SSH	| alt+ENTER: Open in VSCode)+reload(zsh -c 'source $__GHQ_SSH_PLUGIN_PATH; __ghq_search_local')"
    local to_remote="change-prompt([Remote] > )+change-header(CTRL+R: to Local	| alt+ENTER: Open in VSCode)+reload(zsh -c 'source $__GHQ_SSH_PLUGIN_PATH; __ghq_search_remote')"

    local toggle_cmd="transform:echo {fzf:prompt} | grep -q 'Local' && echo \"$to_remote\" || echo \"$to_local\""

    local fzf_out
    fzf_out=$(__ghq_search_local | fzf \
        --ansi \
        --delimiter '\t' \
        --with-nth 4,5 \
        --nth 2 \
        --tiebreak index \
        --prompt="[Local] > " \
        --header="ctrl+R: to Remote SSH	| alt+ENTER: Open in VSCode" \
        --expect=alt-enter \
        --bind "ctrl-r:$toggle_cmd"
    )

    if [[ -z "$fzf_out" ]]; then
        zle reset-prompt 2>/dev/null
        return
    fi

    # 選択結果の取得
    local key_pressed=""
    local result=""

    local lines=("${(f)fzf_out}")
    if [[ ${#lines[@]} -eq 2 ]]; then
        key_pressed="${lines[1]}"
        result="${lines[2]}"
    else
        result="${lines[1]}"
    fi

    local type host repo rest
    IFS=$'\t' read -r type host repo rest <<< "$result"

    if [[ "$type" == "local" ]]; then
        if [[ "$key_pressed" == "alt-enter" ]]; then
            # VS Code で開く
            code -n "$repo"
        else
            # ディレクトリ移動
            cd "$repo"
        fi

    elif [[ "$type" == "remote" ]]; then
        if [[ "$key_pressed" == "alt-enter" ]]; then
            # VS Code Remote で開く
            echo "Opening in VS Code Remote..."
            code --folder-uri "vscode-remote://ssh-remote+$host$repo"
        else
            # SSH で接続
            echo "Connecting to $host..."
            ssh -t "$host" "cd '$repo' && exec \$SHELL -l"
        fi

    elif [[ "$type" == "error" ]]; then
        echo "Error: GHQ_REMOTE_HOSTS is not set."
    fi

    zle reset-prompt 2>/dev/null
}

# 検索を呼び出すキー操作の定義
__ghq_search_widget() {
    BUFFER=""
    __ghq_search
    zle accept-line
}

# Ctrl+G にリポジトリ検索を割り当て
zle -N __ghq_search_widget
bindkey '^g' __ghq_search_widget
