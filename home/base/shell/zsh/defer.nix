{ lib }:

rec {
  command = text: "zsh-defer -m -p -r ${text}";
  source = file: command "source ${lib.escapeShellArg (toString file)}";
  native = name: "# @home-manager-deferred:${name}@";
}
