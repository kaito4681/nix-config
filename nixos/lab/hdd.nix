# ext4 でフォーマット済みのデータ用 HDD．
{ ... }:

{
  fileSystems."/mnt/hdd" = {
    device = "/dev/disk/by-uuid/d590a582-95ac-4060-b6bc-51f8486a6fbc";
    fsType = "ext4";
    options = [
      # HDD が無くても起動を止めない．
      "nofail"
      # 起動時・switch 時の権限設定より先にマウントする．
      "x-systemd.before=systemd-tmpfiles-setup.service"
      "x-systemd.before=systemd-tmpfiles-resetup.service"
    ];
  };

  # 全ユーザーが書き込めるが，他人のファイルは削除できない共有ディレクトリにする．
  # HDD のルートだけに適用し，既存ファイルは変更しない．
  systemd.tmpfiles.rules = [
    "z /mnt/hdd 1777 root root -"
  ];
}
