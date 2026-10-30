{
  config,
  pkgs,
  username,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./nvidia.nix
    ./gpueue.nix
    ./hdd.nix
    ./printing.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Tokyo";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ja_JP.UTF-8";
    LC_IDENTIFICATION = "ja_JP.UTF-8";
    LC_MEASUREMENT = "ja_JP.UTF-8";
    LC_MONETARY = "ja_JP.UTF-8";
    LC_NAME = "ja_JP.UTF-8";
    LC_NUMERIC = "ja_JP.UTF-8";
    LC_PAPER = "ja_JP.UTF-8";
    LC_TELEPHONE = "ja_JP.UTF-8";
    LC_TIME = "ja_JP.UTF-8";
  };

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  users.users.${username} = {
    isNormalUser = true;
    description = username;
    linger = true;
    shell = pkgs.zsh;

    extraGroups = [
      "networkmanager"
      "wheel"
    ];

    packages = with pkgs; [ ];
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.settings.extra-substituters = [ "https://kaito4681-nix-config.cachix.org" ];
  nix.settings.extra-trusted-public-keys = [
    "kaito4681-nix-config.cachix.org-1:WKOffPQiuP7cI/z3JgHO+fQlXrOVbd2g1YY6ykhRYUk="
  ];

  nixpkgs.config.allowUnfree = true;

  # Home Manager の適用前でも管理コマンドを使えるようにする。
  environment.systemPackages = [ pkgs.just ];

  services.openssh = {
    enable = true;
    # 公開鍵は各ユーザーの Home Manager が ~/.ssh/authorized_keys に置く．
    authorizedKeysInHomedir = true;
    # Tailscale 経由でのみ受け付ける．
    openFirewall = false;
    settings = {
      PubkeyAuthentication = true;
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  networking.firewall = {
    enable = true;
    # Tailscale 経由の受信は全ポート許可する．
    trustedInterfaces = [ config.services.tailscale.interfaceName ];
    # その他のインターフェースでは，サービスが明示的に開けるポートのみ許可する．
    # Tailscale 接続用の UDP ポートは services.tailscale.openFirewall で許可する．
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
    # NixOS の標準ファイアウォールは送信を制限せず，その応答も許可する．
  };

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "server";

    extraSetFlags = [
      "--advertise-exit-node"
      "--advertise-routes=10.0.87.0/24,133.7.6.100/32,133.7.6.101/32,202.19.138.120/32"
      "--stateful-filtering=true"
      "--hostname=lab"
    ];
  };

  programs.nix-ld.enable = true;

  # /bin/bash などを決め打ちする外部スクリプト向けに，
  # /bin・/usr/bin の実行ファイルを呼び出し元の PATH から解決する．
  services.envfs.enable = true;

  programs.zsh = {
    enable = true;
    # Home Manager queues completion and prompt initialization with zsh-defer.
    enableGlobalCompInit = false;
    promptInit = "";
  };

  system.stateVersion = "26.05";
}
