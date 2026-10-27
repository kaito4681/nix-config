{
  config,
  lib,
  pkgs,
  ...
}:

let
  # 遅延読み込み用の関数
  defer = command: "zsh-defer -m -p -r ${command}";
  deferSource = file: defer "source ${lib.escapeShellArg (toString file)}";
  deferInit = command: defer "-c ${lib.escapeShellArg ''eval "$(${command})"''}";
in
{
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    defaultKeymap = "emacs";
    history = {
      path = "${config.xdg.stateHome}/zsh/history";
      size = 100000;
      save = 100000;
    };

    completionInit = "";
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
        ${deferInit "PATH=${
          lib.makeBinPath [ config.programs.starship.package ]
        }:$PATH ${lib.getExe config.programs.starship.package} init zsh"}

        # 補完・入力候補・省略入力
        ${deferSource ./completion.zsh}
        ${deferSource "${config.programs.fzf.package}/share/fzf/completion.zsh"}
        ${deferSource "${config.programs.fzf.package}/share/fzf/key-bindings.zsh"}
        ${deferSource "${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh"}
        ${deferSource "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"}
        ${defer "-c '[[ -n $HERDR_ENV ]] && unset ZSH_AUTOSUGGEST_USE_ASYNC; return 0' "}
        ${deferSource "${pkgs.zsh-abbr}/share/zsh/zsh-abbr/zsh-abbr.zsh"}
        ${defer "abbr import-git-aliases --session --prefix g --quiet"}

        # 開発ツールのシェル連携
        ${deferInit "${lib.getExe config.programs.mise.package} activate zsh"}
        ${deferInit "${lib.getExe config.programs.direnv.package} hook zsh"}
        ${deferInit "${lib.getExe config.programs.zoxide.package} init zsh"}

        # SSH・リポジトリ検索・ターミナル連携
        ${deferSource ./integrations/ssh-host-completion.zsh}
        ${deferSource ./integrations/ghq-ssh.zsh}
      '')
      (lib.mkOrder 1030 ''
        # シンタックスハイライト
        ${deferSource "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"}
        ${deferSource ./highlighting.zsh}
        # プロンプトの更新
        zsh-defer -c ':'
      '')
    ];
  };
}
