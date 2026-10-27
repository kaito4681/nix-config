{
  config,
  lib,
  options,
  pkgs,
  ...
}:

let
  defer = import ./defer.nix { inherit lib; };
  definitions = options.programs.zsh.initContent.definitionsWithLocations;
  from = suffix: definition: lib.hasSuffix suffix definition.file;
  core = from "/modules/programs/zsh";
  enabled = {
    completion = config.programs.zsh.enableCompletion;
    plugins = config.programs.zsh.plugins != [ ];
    autosuggestion = config.programs.zsh.autosuggestion.enable;
    highlighting = config.programs.zsh.syntaxHighlighting.enable;
    fzf = config.programs.fzf.enable && config.programs.fzf.enableZshIntegration;
    starship = config.programs.starship.enable && config.programs.starship.enableZshIntegration;
    mise = config.programs.mise.enable && config.programs.mise.enableZshIntegration;
    direnv = config.programs.direnv.enable && config.programs.direnv.enableZshIntegration;
    zoxide = config.programs.zoxide.enable && config.programs.zoxide.enableZshIntegration;
  };

  # 標準モジュールが生成した初期化コード
  selectors = {
    completion = d: core d && d.value == config.programs.zsh.completionInit;
    plugins = d: from "/modules/programs/zsh/plugins" d && lib.hasInfix "# Source plugins" d.value;
    autosuggestion = d: core d && lib.hasPrefix "source ${pkgs.zsh-autosuggestions}/" d.value;
    highlighting =
      d: core d && lib.hasPrefix "source ${config.programs.zsh.syntaxHighlighting.package}/" d.value;
    fzf = from "/modules/programs/fzf.nix";
    starship = from "/modules/programs/starship.nix";
    mise = from "/modules/programs/mise.nix";
    direnv = from "/modules/programs/direnv.nix";
    zoxide = from "/modules/programs/zoxide.nix";
  };
  blocks = lib.mapAttrs (
    _: select: builtins.filter (d: d.value != "" && select d) definitions
  ) selectors;
  names = builtins.attrNames blocks;
  selected = lib.concatMap (name: blocks.${name}) names;

  # Starship がプロファイルではなく実体のパスを使うようにする。
  prepare =
    name: text:
    if name == "starship" then
      lib.replaceStrings
        [ "${lib.getExe config.programs.starship.package} init zsh" ]
        [
          "PATH=${
            lib.makeBinPath [ config.programs.starship.package ]
          }:$PATH ${lib.getExe config.programs.starship.package} init zsh"
        ]
        text
    else
      text;
  render =
    name:
    if !enabled.${name} then
      ""
    else
      assert lib.assertMsg (builtins.length blocks.${name} == 1)
        "Expected one Home Manager zsh initialization block for ${name}; review zsh/deferred.nix after updating Home Manager.";
      defer.source (
        pkgs.writeText "zsh-${name}-init.zsh" (prepare name (builtins.head blocks.${name}).value)
      );
in
{
  # 同期読み込みを除き、指定位置で標準コードを遅延実行する。
  options.programs.zsh.initContent = lib.mkOption {
    apply =
      text:
      if !config.programs.zsh.enable then
        text
      else
        assert lib.assertMsg (lib.all (
          name: !enabled.${name} || lib.hasInfix (defer.native name) text
        ) names) "Missing a deferred zsh initialization position; review zsh/default.nix.";
        lib.replaceStrings ((map (d: d.value) selected) ++ (map defer.native names)) (
          (map (_: "") selected) ++ (map render names)
        ) text;
  };
}
