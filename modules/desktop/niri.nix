{
  config,
  inputs,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;

  # iNiR 2.27.0 contains a legacy Hyprland-only Python helper with an
  # `env -S` shell trampoline that Nix's automatic patchShebangs hook cannot
  # parse. It is not used by Niri, but its executable bit makes the package
  # fixup phase inspect it and abort the entire system build. Give that helper
  # a normal Python shebang before the standard fixup hooks run.
  patchedInir = inputs.inir.packages.${system}.default.overrideAttrs (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + ''
      sed -i '1c\#!${pkgs.python3}/bin/python3' scripts/hyprland/get_keybinds.py
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
