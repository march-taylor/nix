{ pkgs, ... }:
{
  home.packages = with pkgs; [
    codex
    gcc
    uv

    # Provides both `node` and `npm`.
    nodejs

    cargo
    clippy
    rustc
    rustfmt

    fd
    jq
    micro
    ripgrep
  ];
}
