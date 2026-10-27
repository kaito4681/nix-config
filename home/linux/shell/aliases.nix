{ ... }:

let
  nvidiaAlias = ''
    if command -v nvidia-smi >/dev/null 2>&1; then
      alias ns='nvidia-smi'
    fi
  '';
in
{
  # NVIDIA GPU の状態表示
  programs.bash.initExtra = nvidiaAlias;
  programs.zsh.initContent = nvidiaAlias;
}
