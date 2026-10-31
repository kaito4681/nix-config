{
  username,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./appearance.nix
    ./input.nix
    ./desktop.nix
    ./finder.nix
    ./tailscale.nix
  ];

  # ホストとユーザーの基本設定。
  nixpkgs.hostPlatform = "aarch64-darwin"; # Apple Silicon のMac向けにビルドする。
  nixpkgs.config.allowUnfree = true; # ライセンスが非自由なパッケージの利用を許可する。

  users.users.${username} = {
    home = "/Users/${username}"; # 既存ユーザーのホームディレクトリを指定する。
    shell = pkgs.zsh; # ログインシェルをNix管理のzshにする。
  };
  programs.zsh.enable = true; # zsh本体とシステム共通の起動設定を管理する。
  environment.shells = [ pkgs.zsh ]; # Nix管理のzshを/etc/shellsの許可リストに登録する。
  # 既存の管理者ユーザーはknownUsersに追加せず、ログインシェルだけを更新する。
  system.activationScripts.postActivation.text = lib.mkAfter ''
    if [[ "$(/usr/bin/dscl . -read ${lib.escapeShellArg "/Users/${username}"} UserShell)" != "UserShell: /run/current-system/sw/bin/zsh" ]]; then
      /usr/bin/dscl . -create ${lib.escapeShellArg "/Users/${username}"} UserShell /run/current-system/sw/bin/zsh || exit 1
    fi
  '';
  system.primaryUser = username; # ユーザー単位のMac設定を適用する対象を指定する。

  security.pam.services.sudo_local.touchIdAuth = true; # sudo で Touch ID を使う

  nix.settings = {
    # nix-darwin が /etc/nix/nix.conf と nix-daemon を管理する
    experimental-features = [
      # nixコマンドとFlakesを有効にする。
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      # rootとこのユーザーに、Nixの信頼済み利用者としての権限を与える。
      "root"
      username
    ];
    always-allow-substitutes = true; # 導出側の指定にかかわらず、バイナリキャッシュの利用を許可する。
    extra-substituters = [ "https://kaito4681-nix-config.cachix.org" ]; # このリポジトリ用のCachixを追加のバイナリキャッシュとして使う。
    extra-trusted-public-keys = [
      # Cachixから取得した成果物の署名検証に使う公開鍵。
      "kaito4681-nix-config.cachix.org-1:WKOffPQiuP7cI/z3JgHO+fQlXrOVbd2g1YY6ykhRYUk="
    ];
  };
  nix.optimise.automatic = true; # ストア内の同一ファイルを定期的にハードリンクで共有し、容量を節約する。

  nix.gc = {
    # 毎週日曜の午前3時に、30日より古い世代と未参照のストアを削除する。
    automatic = true; # launchdでGCを定期実行する。
    interval = {
      Weekday = 0; # 日曜日。
      Hour = 3; # 午前3時。
      Minute = 0; # 0分。
    };
    options = "--delete-older-than 30d"; # 30日より古い世代を削除し、参照されなくなったストアを回収する。
  };

  system.stateVersion = 6; # 互換性の基準。nix-darwin更新時も安易に変更しない。
}
