{ username, ... }:

{
  nix-homebrew = {
    enable = true;
    user = username;
    autoMigrate = true; # 既存のHomebrewをnix-homebrew管理へ移行する。
    trust.casks = [
      "stablyai/orca/orca"
      "steipete/tap/codexbar"
    ];
  };

  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "none"; # 宣言していない既存アプリやformulaは削除しない。
      autoUpdate = true;
      upgrade = true;
    };

    taps = [
      "stablyai/orca"
      "steipete/tap"
    ];

    casks = [
      # システム・ユーティリティ
      "betterdisplay"
      "blackhole-2ch"
      "hammerspoon"
      "pearcleaner"
      "raycast"

      # AI・コーディングエージェント
      "chatgpt"
      "claude-code"
      "stablyai/orca/orca"
      "steipete/tap/codexbar"
      "t3-code"

      # ターミナル・開発
      "ghostty@tip"
      "raspberry-pi-imager"
      "sf-symbols"
      "utm"
      "wezterm@nightly"
      "zed"

      # ドキュメント・仕事・研究
      "drawio"
      "libreoffice"
      "linear"
      "mactex-no-gui"
      "obsidian"
      "zotero"
    ];
  };
}
