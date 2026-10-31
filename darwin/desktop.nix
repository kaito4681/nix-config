{
  system.defaults = {
    # Dock・Spaces・ウィンドウの動作。
    dock = {
      autohide = true; # Dockを自動的に表示・非表示にする。
      orientation = "bottom"; # Dockを画面の下に配置する。
      tilesize = 50; # Dockのアイコンサイズを50にする。
      magnification = true; # ポインタを重ねたDockアイコンを拡大する。
      largesize = 54; # Dockアイコンの拡大時サイズを54にする。
      mineffect = "scale"; # ウィンドウをしまうときにスケールエフェクトを使う。
      minimize-to-application = false; # しまったウィンドウをアプリアイコンにまとめず、Dockに個別表示する。
      launchanim = true; # アプリ起動時にDockアイコンをアニメーション表示する。
      show-process-indicators = true; # 起動中のアプリにインジケータを表示する。
      showAppExposeGestureEnabled = true; # 上下スワイプでApp Exposéを表示する操作を有効にする。
      show-recents = false; # 提案されたアプリや最近使ったアプリをDockに追加表示しない。
      mru-spaces = false; # 最近の使用状況に基づくSpacesの自動並べ替えを無効にする。
      expose-group-apps = true; # Mission Controlのウィンドウをアプリごとにまとめる。
    };

    spaces.spans-displays = false; # 各ディスプレイに個別の操作スペースを割り当てる。

    WindowManager = {
      GloballyEnabled = false; # ステージマネージャを無効にする。
      EnableStandardClickToShowDesktop = true; # 壁紙のクリックでデスクトップを表示する動作を常に有効にする。
      HideDesktop = false; # ステージマネージャ使用時もデスクトップの項目を表示する。
      StandardHideDesktopIcons = false; # 通常時にデスクトップの項目を表示する。
      StandardHideWidgets = false; # 通常時にデスクトップのウィジェットを表示する。
      StageManagerHideWidgets = true; # ステージマネージャ使用時はウィジェットを隠す。
      EnableTilingByEdgeDrag = true; # 画面の左右端へドラッグしてウィンドウをタイル表示する。
      EnableTopTilingByEdgeDrag = false; # メニューバーへドラッグしてフルスクリーンにする動作を無効にする。
      EnableTilingOptionAccelerator = true; # Optionキーを押しながらドラッグしてタイル表示する。
      EnableTiledWindowMargins = false; # タイル表示するウィンドウ間に余白を入れない。
    };

    CustomUserPreferences = {
      # 専用オプションがない設定。
      NSGlobalDomain = {
        AppleActionOnDoubleClick = "None"; # ウィンドウのタイトルバーをダブルクリックしても何もしない。
        NSCloseAlwaysConfirmsChanges = false; # 書類を閉じるときの変更保持の確認を無効にする。
        NSQuitAlwaysKeepsWindows = true; # アプリ終了時にウィンドウを閉じず、次回起動時の復元を有効にする。
      };
      "com.apple.dock"."workspaces-auto-swoosh" = false; # アプリ切り替え時に、そのウィンドウがある操作スペースへ自動移動しない。
    };
  };
}
