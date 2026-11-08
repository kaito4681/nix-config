{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  makeWrapper,
  autoPatchelfHook,
  stdenv,
  openssl,
  zlib,
}:
let
  version = "0.1.7";
  darwin = stdenvNoCC.hostPlatform.isDarwin;
  app = "T3 Code (Beta)";
  privacy = "--set T3CODE_TELEMETRY_ENABLED false --set T3CODE_OTEL_SDK_DISABLED true --set T3CODE_DISABLE_AUTO_UPDATE 1";
in
stdenvNoCC.mkDerivation {
  pname = "t3code-official";
  inherit version;
  src = fetchurl (
    if darwin then
      {
        url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-arm64.zip";
        hash = "sha256-N6TwR0kLg+jX4OTtD47ZAzji0gNlXgopNiHyTBOSF6E=";
      }
    else
      {
        url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/t3-${version}-linux-x64.tar.gz";
        hash = "sha256-wImJK/eSLi5zxvRKXR6hJcmfcON4wYNhy77S+6GSDmw=";
      }
  );
  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.optionals darwin [ unzip ]
  ++ lib.optionals (!darwin) [ autoPatchelfHook ];
  buildInputs = lib.optionals (!darwin) [
    stdenv.cc.cc.lib
    openssl
    zlib
  ];
  dontBuild = true;
  # Node SEA embeds its application in ELF sections; stripping corrupts that payload.
  dontStrip = true;
  # Preserve Apple's upstream code signature, including the executable and Info.plist.
  dontFixup = darwin;
  unpackPhase = lib.optionalString darwin ''
    runHook preUnpack
    unzip -q "$src"
    runHook postUnpack
  '';
  installPhase =
    if darwin then
      ''
        runHook preInstall
        mkdir -p "$out/Applications" "$out/bin"
        cp -R "${app}.app" "$out/Applications/"
        makeWrapper "$out/Applications/${app}.app/Contents/MacOS/${app}" "$out/bin/t3code" ${privacy}
        makeWrapper "$out/Applications/${app}.app/Contents/MacOS/${app}" "$out/bin/t3" ${privacy} \
          --set ELECTRON_RUN_AS_NODE 1 \
          --add-flags "\"$out/Applications/${app}.app/Contents/Resources/app.asar/apps/server/dist/bin.mjs\""
        runHook postInstall
      ''
    else
      ''
        runHook preInstall
        mkdir -p "$out/libexec/t3code" "$out/bin"
        cp -R . "$out/libexec/t3code/"
        # glibc hosts select the gnu variant; the bundled musl variant cannot run here.
        rm -rf "$out/libexec/t3code/node_modules/@yuuang/ffi-rs-linux-x64-musl"
        makeWrapper "$out/libexec/t3code/t3" "$out/bin/t3" ${privacy}
        runHook postInstall
      '';
  meta = {
    description = "Official T3 Code release with privacy defaults";
    homepage = "https://t3.codes";
    license = lib.licenses.mit;
    platforms = [
      "aarch64-darwin"
      "x86_64-linux"
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = if darwin then "t3code" else "t3";
  };
}
