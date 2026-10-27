{
  config,
  lib,
  pkgs,
  ...
}:

let
  graphics = config.hardware.graphics;

  # nvidia-smi などの CLI ツールは RUNPATH で自分の世代のライブラリに直接紐付いているため、
  # /run/opengl-driver を起動中の世代に向け直すだけでは直らない。各ツールを
  # 起動中世代の実体に向け直すラッパーで上書きする。
  executables = [
    "nvidia-cuda-mps-control"
    "nvidia-cuda-mps-server"
    "nvidia-debugdump"
    "nvidia-powerd"
    "nvidia-smi"
  ];
  bootedTools = pkgs.symlinkJoin {
    name = "booted-nvidia-tools";
    paths = map (
      name:
      pkgs.writeShellScriptBin name ''
        exec /run/nvidia-booted-bin/bin/${name} "$@"
      ''
    ) executables;
  };

  drivers = pkgs.buildEnv {
    name = "booted-graphics-drivers";
    paths = [ graphics.package ] ++ graphics.extraPackages;
  };
  drivers32 = pkgs.buildEnv {
    name = "booted-graphics-drivers-32bit";
    paths = [ graphics.package32 ] ++ graphics.extraPackages32;
  };
in
{
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  # 各世代のビルド物から、その世代のドライバ一式・CLIツールの実体を辿れるようにしておく。
  system.systemBuilderCommands = ''
    ln -s ${drivers} $out/graphics-drivers
    ln -s ${lib.getBin config.hardware.nvidia.package} $out/nvidia-bin
    ${lib.optionalString graphics.enable32Bit "ln -s ${drivers32} $out/graphics-drivers-32"}
  '';

  # 本来の tmpfiles ルールは switch のたびに /run/opengl-driver を新しい世代に
  # 向け直してしまう(カーネルモジュールは再起動まで更新されないため不整合の原因になる)。
  # 無効化し、代わりに activation 側で「起動中の世代」に向け直す。
  systemd.tmpfiles.settings.graphics-driver = lib.mkForce { };

  system.activationScripts.bootedGraphicsDrivers.text = ''
    # 起動時の activation は /run/booted-system が stage 2 で作られるより前に走るため、
    # そのタイミングでは「これから起動する世代 = 起動中の世代」とみなす。
    booted=/run/booted-system
    [ -e "$booted" ] || booted="$systemConfig"

    link_booted_graphics() {
      local path="$1" generation_link="$2" target="" type rule_path mode user group age rule_target
      if [ -e "$generation_link" ]; then
        target="$generation_link"
      elif [ -f "$booted/etc/tmpfiles.d/graphics-driver.conf" ]; then
        # この仕組み導入前の世代には graphics-drivers リンクが無いので、
        # 当時の tmpfiles ルールから元のドライバ環境を復元する。
        while read -r type rule_path mode user group age rule_target; do
          if [ "$rule_path" = "'$path'" ]; then
            target="$rule_target"
            break
          fi
        done < "$booted/etc/tmpfiles.d/graphics-driver.conf"
      fi
      if [ -n "$target" ]; then
        ln -sfnT "$target" "$path.tmp"
        mv -Tf "$path.tmp" "$path"
      else
        echo "Cannot find the booted graphics environment for $path" >&2
      fi
    }

    link_booted_graphics /run/opengl-driver "$booted/graphics-drivers"
    ${lib.optionalString graphics.enable32Bit ''
      link_booted_graphics /run/opengl-driver-32 "$booted/graphics-drivers-32"
    ''}

    if [ -e "$booted/nvidia-bin" ]; then
      bin="$booted/nvidia-bin"
    else
      # この仕組みを初めて導入する switch では、古い世代はまだ nvidia-bin リンクを
      # 持っていないので、その世代の PATH から実体を辿る。
      old_smi=$(readlink -f "$booted/sw/bin/nvidia-smi")
      bin=$(dirname "$(dirname "$old_smi")")
    fi
    ln -sfnT "$bin" /run/nvidia-booted-bin.tmp
    mv -Tf /run/nvidia-booted-bin.tmp /run/nvidia-booted-bin
  '';

  # nvidia_x11.bin がそのまま提供する nvidia-smi 等より優先させ、起動中のカーネルモジュールに
  # 対応するバイナリを使わせる。
  environment.systemPackages = [ (lib.hiPrio bootedTools) ];
}
