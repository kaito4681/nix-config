{ config, lib, ... }:

{
  config.programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    settings = {
      format = "$shell\${custom.hostname_ssh_agent}\${custom.hostname_no_ssh_agent}$directory$character";
      add_newline = false;
      shell = {
        disabled = false;
        format = "[$indicator]($style)";
        style = "bold blue";
        bash_indicator = "\\[bash\\]($style) ";
        zsh_indicator = "";
        fish_indicator = "\\[fish\\]($style) ";
      };
      custom.hostname_ssh_agent = {
        command = "hostname -s";
        format = "[\\($output\\)]($style) ";
        style = "bold bright-yellow";
        when = ''test -n "$SSH_CONNECTION" && test -S "$SSH_AUTH_SOCK"'';
      };
      custom.hostname_no_ssh_agent = {
        command = "hostname -s";
        format = "[\\($output\\)]($style) ";
        style = "";
        when = ''test -n "$SSH_CONNECTION" && ! test -S "$SSH_AUTH_SOCK"'';
      };
    };
  };

  # プロファイルの切り替え後も使えるパスで Starship を初期化
  options.programs.bash.initExtra = lib.mkOption {
    apply =
      text:
      lib.replaceStrings
        [ "${lib.getExe config.programs.starship.package} init bash" ]
        [
          "PATH=${
            lib.makeBinPath [ config.programs.starship.package ]
          }:$PATH ${lib.getExe config.programs.starship.package} init bash"
        ]
        text;
  };
}
