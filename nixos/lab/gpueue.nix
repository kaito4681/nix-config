{ pkgs, username, ... }:

{
  services.gpueue = {
    enable = true;
    admins = [ username ];
    cudaCheckpointPackage = pkgs.callPackage ./cuda-checkpoint.nix { };

    # 既定値は hardware.nvidia.package (= 最新の世代) を指すが，カーネルモジュールは
    # 再起動まで更新されない．nvidia.nix が用意する起動中の世代のものを使う．
    nvidiaSmiPath = "/run/nvidia-booted-bin/bin/nvidia-smi";
    nvmlLibrary = "/run/opengl-driver/lib/libnvidia-ml.so.1";
  };
}
