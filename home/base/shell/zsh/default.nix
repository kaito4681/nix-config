{
  config,
  lib,
  pkgs,
  ...
}:

let
  defer = import ./defer.nix { inherit lib; };
in
{
  imports = [
    ./plugins.nix
    ./deferred.nix
  ];

  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    defaultKeymap = "emacs";
    history = {
      path = "${config.xdg.stateHome}/zsh/history";
      size = 100000;
      save = 100000;
    };

    completionInit = builtins.readFile ./completion.zsh;
    initContent = lib.mkMerge [
      (lib.mkOrder 990 ''
        source ${pkgs.zsh-defer}/share/zsh-defer/zsh-defer.plugin.zsh
        # ターミナル連携と起動直後のプロンプト
        source ${./integrations/ssh-terminal.zsh}
        setopt prompt_subst
        PROMPT='%F{cyan}%1~%f %F{green}❯%f '
      '')
      (lib.mkOrder 1010 ''
        # Starship の読み込み
        ${defer.native "starship"}

        # 補完・入力候補・省略入力
        ${defer.native "completion"}
        ${defer.native "fzf"}
        ${defer.native "plugins"}
        ${defer.native "autosuggestion"}
        ${defer.command "-c '[[ -n $HERDR_ENV ]] && unset ZSH_AUTOSUGGEST_USE_ASYNC; return 0'"}

        # 開発ツールのシェル連携
        ${defer.native "mise"}
        ${defer.native "direnv"}
        ${defer.native "zoxide"}

        # SSH・リポジトリ検索・ターミナル連携
        ${defer.source ./integrations/ssh-host-completion.zsh}
        ${defer.source ./integrations/ghq-ssh.zsh}
      '')
      (lib.mkOrder 1030 ''
        # シンタックスハイライト
        ${defer.native "highlighting"}
        # プロンプトの更新
        zsh-defer -c ':'
      '')
    ];
  };
}
