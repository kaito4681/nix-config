{
  system.defaults = {
    # Finder の表示とスクリーンショットの保存先。
    NSGlobalDomain.AppleShowAllExtensions = true; # すべてのファイル名拡張子を表示する。

    finder = {
      ShowPathbar = true; # Finderの下部にパスバーを表示する。
      ShowStatusBar = true; # Finderの下部に項目数などのステータスバーを表示する。
      FXPreferredViewStyle = "clmv"; # Finderの標準表示形式をカラム表示にする。
      FXDefaultSearchScope = "SCcf"; # 検索開始時の範囲を現在のフォルダにする。
      _FXSortFoldersFirst = true; # 名前順の表示でフォルダを先頭に並べる。
      ShowExternalHardDrivesOnDesktop = false; # 外部ディスクをデスクトップに表示しない。
      ShowHardDrivesOnDesktop = false; # 内蔵ハードディスクをデスクトップに表示しない。
      ShowMountedServersOnDesktop = false; # 接続中のサーバをデスクトップに表示しない。
      ShowRemovableMediaOnDesktop = true; # CD・DVDなどのリムーバブルメディアをデスクトップに表示する。
    };

    screencapture.location = "~/Downloads"; # スクリーンショットをダウンロードフォルダに保存する。
  };
}
