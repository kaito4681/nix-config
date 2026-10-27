{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.zsh = {
    plugins = [
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];

    autosuggestion.enable = true;
    zsh-abbr = {
      enable = true;
      abbreviations = {
        d = "docker";
        g = "git";
      }
      // lib.mapAttrs' (
        name: _: lib.nameValuePair "g${name}" "g ${name}"
      ) config.programs.git.settings.alias;
    };

    syntaxHighlighting = {
      enable = true;
      highlighters = [ "brackets" ];
      styles = {
        command = "fg=blue,bold";
        alias = "fg=blue,bold";
        function = "fg=blue,bold";
        builtin = "fg=blue,bold";
        unknown-token = "fg=red,bold";
        double-quoted-argument = "fg=yellow";
        single-quoted-argument = "fg=yellow";
        path = "underline";
      };
    };
  };
}
