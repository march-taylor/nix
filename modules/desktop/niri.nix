{
  config,
  inputs,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;

  # Upstream currently ships two executable Python helpers with an env -S
  # trampoline that Nix patchShebangs cannot parse. Keep the upstream package,
  # dependencies, wrapper and module unchanged; only normalize those two first
  # lines before the package's normal fixup phase.
  inirPackage = inputs.inir.packages.${system}.default.overrideAttrs (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + ''
      sed -i '1c\#!${pkgs.python3}/bin/python3' \
        scripts/hyprland/get_keybinds.py \
        scripts/colors/generate_colors_material.py
    '';
  });
in
{
  programs.niri.enable = true;

  # This is the integration documented by iNiR itself. The upstream module:
  # - installs the wrapped iNiR package system-wide;
  # - carries Quickshell and all runtime dependencies in the wrapper PATH;
  # - creates inir.service;
  # - wires it to niri.service.wants so it starts and stops with Niri.
  programs.inir = {
    enable = true;
    package = inirPackage;
    service.compositor = "niri";
    extraPackages = [ config.programs.niri.package ];
  };

  environment.systemPackages = with pkgs; [
    xwayland-satellite
    wl-clipboard
    cliphist
    grim
    slurp
    swappy
    brightnessctl
    playerctl
    pavucontrol
    networkmanagerapplet
    libnotify
    xdg-utils
  ];
}
