{
  system.defaults = {
    # キーボード・マウス・トラックパッドの操作。
    NSGlobalDomain = {
      AppleKeyboardUIMode = 3; # Tab / Shift+Tab でコントロール間のフォーカスを移動する。
      InitialKeyRepeat = 30; # キーを押し続けてからリピートが始まるまでの待ち時間を設定する。
      KeyRepeat = 2; # キーのリピート間隔を設定する（小さいほど速い）。
      NSAutomaticCapitalizationEnabled = false; # 文頭を自動で大文字にしない。
      NSAutomaticInlinePredictionEnabled = false; # インラインの予測テキストを表示しない。
      NSAutomaticPeriodSubstitutionEnabled = false; # スペース2回でピリオドを入力しない。
      NSAutomaticSpellingCorrectionEnabled = false; # 英字入力中のスペルを自動修正しない。
      NSAutomaticQuoteSubstitutionEnabled = false; # 引用符をスマート引用符へ自動変換しない。
      NSAutomaticDashSubstitutionEnabled = false; # ハイフンの連続入力をダッシュへ自動変換しない。
      "com.apple.swipescrolldirection" = true; # 指の動きに合わせるナチュラルスクロールを使う。
      "com.apple.trackpad.scaling" = 3.0; # トラックパッドで動かすポインタの速度を設定する。
    };

    ".GlobalPreferences"."com.apple.mouse.scaling" = 3.0; # マウスで動かすポインタの速度を設定する。
    hitoolbox.AppleFnUsageType = "Do Nothing"; # Fn / 地球儀キー単独では何もしない。

    trackpad = {
      Clicking = false; # タップだけでクリックする操作を無効にする。
      Dragging = false; # タップによるドラッグを無効にする。
      DragLock = false; # ドラッグロックを無効にする。
      FirstClickThreshold = 2; # 通常クリックに必要な押す強さを「強い」にする（2）。
      SecondClickThreshold = 2; # 強めのクリックに必要な押す強さを「強い」にする（2）。
      ActuateDetents = true; # クリック時の触覚フィードバックを有効にする。
      ForceSuppressed = false; # 強めのクリックを抑止せず、利用可能にする。
      TrackpadRightClick = true; # 2本指のクリックによる副ボタンクリックを有効にする。
      TrackpadCornerSecondaryClick = 0; # 左右の隅を押す副ボタンクリックは使わない（0）。
      TrackpadThreeFingerDrag = false; # 3本指でのドラッグを無効にする。
      TrackpadThreeFingerTapGesture = 0; # 3本指タップで「調べる＆データ検出」を開かない（0）。
      TrackpadThreeFingerHorizSwipeGesture = 2; # 3本指の左右スワイプでフルスクリーンアプリを切り替える（2）。
      TrackpadThreeFingerVertSwipeGesture = 2; # 3本指の上下スワイプを有効にする（上: Mission Control、下: App Exposé）。
      TrackpadFourFingerHorizSwipeGesture = 2; # 4本指の左右スワイプも有効にする（画面では3本指の設定が優先される）。
      TrackpadFourFingerVertSwipeGesture = 2; # 4本指の上下スワイプも有効にする（3本指と同時有効時は3本指を優先）。
      TrackpadFourFingerPinchGesture = 2; # 親指と3本指でピンチ／広げるジェスチャを有効にする（2）。
      TrackpadMomentumScroll = true; # 指を離した後も続く慣性スクロールを使う。
      TrackpadPinch = true; # 2本指のピンチで拡大・縮小する。
      TrackpadRotate = true; # 2本指で回転するジェスチャを有効にする。
      TrackpadTwoFingerDoubleTapGesture = true; # 2本指のダブルタップでスマートズームする。
      TrackpadTwoFingerFromRightEdgeSwipeGesture = 0; # 右端から2本指で通知センターを開く操作を無効にする（0）。
    };
  };
}
