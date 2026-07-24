{
  config,
  inputs,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;

  # iNiR 2.27.0 contains two Python helpers with an `env -S` shell trampoline
  # that Nix's automatic patchShebangs hook cannot parse. One is Hyprland-only,
  # but both become executable during packaging, so either can abort the whole
  # NixOS build. Replace only their first lines with a normal Python shebang
  # before the standard fixup hooks run.
  patchedInir = inputs.inir.packages.${system}.default.overrideAttrs (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + ''
      for helper in \
        scripts/hyprland/get_keybinds.py \
        scripts/colors/generate_colors_material.py
      do
        sed -i '1c\#!${pkgs.python3}/bin/python3' "$helper"
      done
    '';
  });
in
{
  programs.niri.enable = true;

  programs.inir = {
    enable = true;
    package = patchedInir;
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
