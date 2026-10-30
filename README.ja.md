# NixOS and Home Manager configuration

[English](README.md)

## セットアップ

NixOS 以外の Linux または macOS では、先に[Nix](https://github.com/NixOS/nix-installer) をインストールしてください。

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
```

このリポジトリを clone します。

```bash
nix shell nixpkgs#git --command git clone https://github.com/kaito4681/nix-config.git ~/ghq/github.com/kaito4681/nix-config
cd ~/ghq/github.com/kaito4681/nix-config
```

インストール後は新しいターミナルを開いてください。

適用する前に、自分のアカウント用に `settings.nix`の`username`,`githubName`,`githubEmail`を編集後、`sshKeys`を取得するために次のコマンドを実行してください。

```bash
nix shell --inputs-from . nixpkgs#python3 nixpkgs#openssh --command python3 ci/ssh-keys/update.py
```

```bash
# NixOS
sudo nixos-rebuild switch --flake .#<host>
just home apply <host>

# Linux (NixOS 以外)
nix run .#home-manager -- switch --flake .#linux

# macOS (Apple Silicon)
nix run .#home-manager -- switch --flake .#darwin
```

GitHub にログインします。

```bash
gh auth login
```

NixOS では、Tailscale にもログインします。

```bash
sudo tailscale login
sudo systemctl restart tailscaled-set.service
```

[Tailscale 管理コンソール](https://console.tailscale.com/admin/machines) で、
advertise されたルートと exit node を承認してください。

NixOS では、Docker 用の環境変数を読み直します。

```bash
source /etc/set-environment
```

## CI のキャッシュ

GitHub Actions は Cachix を利用します。Cachix で公開キャッシュを作成し、
Repository variable `CACHIX_CACHE` にキャッシュ名、Repository secret
`CACHIX_AUTH_TOKEN` にそのキャッシュへの書き込みトークンを設定してください。
キャッシュ名が未設定の場合はキャッシュ処理をスキップします。
Pull request ではキャッシュの読み取りのみ行います。

`lab` は NixOS 設定の適用後にキャッシュを自動利用します。
flake にもキャッシュ設定があり、`nix build --accept-flake-config` などで利用できます。
ただし Nix daemon が設定の追加を許可しない環境では、管理者による設定が必要です。
NixOS 以外では `nix run nixpkgs#cachix -- use kaito4681-nix-config` で設定できます。

## コマンド

`nix develop` を実行すると、コミット時に nixfmt を実行する Git hook が登録されます。
direnv を使う場合は、初回に `direnv allow` を実行すると、ディレクトリに入るたびに同じ開発環境が自動で読み込まれます。
全 Nix ファイルの整形は `nix fmt`、整形チェックは `nix flake check` で実行できます。

```bash
just                       # コマンド一覧を表示
just update                # 依存関係を更新
just apply lab             # NixOS と Home Manager を適用
just home apply <host>     # Home Manager を適用
just home build <host>     # 適用せずに Home Manager をビルド
just nixos apply lab       # NixOS を適用
just nixos build lab       # 適用せずに NixOS をビルド
just check                 # flake をチェック
just fmt                   # Nix ファイルを整形
just show                  # 設定一覧を表示
```

Home Manager のホスト: `lab`、`linux`、`darwin`(Apple Silicon)。
