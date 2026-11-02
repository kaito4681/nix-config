{
  programs.mas = {
    enable = true; # Nixでmasを入れ、App Storeアプリを宣言的にインストールする。
    update = false; # 適用時の更新は行わず、App Storeの自動更新に任せる。
    cleanup = false; # 一覧にないApp Storeアプリを削除しない。

    packages = {
      Tailscale = 1475387142;
    };
  };

  # App Storeアプリの自動更新を有効にする。
  system.defaults.CustomSystemPreferences."com.apple.commerce".AutoUpdate = true;
}
