{ lib, pkgs, ... }:

{
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.local/share/mise/shims"
    "$HOME/.bun/bin"
    "$HOME/.cargo/bin"
  ] ++ lib.optional pkgs.stdenv.hostPlatform.isDarwin "/Library/TeX/texbin";
}
