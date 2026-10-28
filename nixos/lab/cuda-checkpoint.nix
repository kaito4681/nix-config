# NVIDIA の cuda-checkpoint (nixpkgs に無いため自前でパッケージ化する)．
{
  lib,
  stdenv,
  fetchFromGitHub,
  autoPatchelfHook,
  autoAddDriverRunpath,
}:

stdenv.mkDerivation {
  pname = "cuda-checkpoint";
  version = "610";
  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "cuda-checkpoint";
    rev = "00d5cce84c628088d6caa203fc4af40c1538b6f7";
    hash = "sha256-J+48Z5EjKpjhMhaUZOqeOB7BZsLN/+Ut2oGnLxX3a9c=";
  };
  # libcuda.so.1 は /run/opengl-driver/lib (起動中の世代のドライバ) から読む．
  nativeBuildInputs = [
    autoPatchelfHook
    autoAddDriverRunpath
  ];
  autoPatchelfIgnoreMissingDeps = [ "libcuda.so.1" ];
  dontBuild = true;
  installPhase = ''
    install -Dm755 bin/${stdenv.hostPlatform.uname.processor}_Linux/cuda-checkpoint $out/bin/cuda-checkpoint
  '';
  meta = {
    license = lib.licenses.unfree;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
