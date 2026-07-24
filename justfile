set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

check:
    nix flake check

fmt:
    nix fmt

build:
    sudo nixos-rebuild build --flake .#desktop

test:
    sudo nixos-rebuild test --flake .#desktop

switch:
    sudo nixos-rebuild switch --flake .#desktop

update:
    nix flake update
    sudo nixos-rebuild test --flake .#desktop

update-inir:
    nix flake update inir
    sudo nixos-rebuild test --flake .#desktop

iso:
    nix build .#installer-iso

offline-iso:
    nix build .#offline-installer-iso
