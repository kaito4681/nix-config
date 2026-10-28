{ ... }:

{
  imports = [ ./aliases.nix ];

  # VS Code のサーバーや tmux など長く動くプロセスから起動したシェルは，nixos-rebuild switch 前の
  # 環境を引き継ぎ，/etc/zshenv も /etc/set-environment を読み直さない．中身 (ストアパス) が
  # 変わっていれば読み直し，PATH に後から足された項目 (VS Code の code など) は後ろに残す．
  programs.zsh.envExtra = ''
    if [[ -r /etc/set-environment ]]; then
      () {
        local src=''${''${:-/etc/set-environment}:A}
        [[ $src == ''${__NIXOS_SET_ENVIRONMENT_SRC-} ]] && return
        local -a old_path=($path)
        source /etc/set-environment
        path+=(''${old_path:|path})
        export __NIXOS_SET_ENVIRONMENT_SRC=$src
      }
    fi
  '';
}
