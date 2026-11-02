{
  system.defaults = {
    # 外観・メニューバー・時計の表示。
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark"; # 外観をダークモードにする。
      AppleShowScrollBars = "Always"; # スクロールバーを常に表示する。
      _HIHideMenuBar = false; # メニューバーを自動的に隠さない。
      "com.apple.sound.beep.feedback" = 0; # 音量キー操作時のフィードバック音を鳴らさない。
    };

    menuExtraClock = {
      Show24Hour = true; # 時計を24時間表示にする。
      ShowDate = 1; # 時計に日付を常に表示する（1 = 常に）。
      ShowDayOfWeek = true; # 時計に曜日を表示する。
      ShowSeconds = true; # 時計に秒を表示する。
      FlashDateSeparators = false; # 時刻の区切り記号を点滅させない。
      IsAnalog = false; # アナログ時計ではなくデジタル時計を使う。
    };
  };
}
