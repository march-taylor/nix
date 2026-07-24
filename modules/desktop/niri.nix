{
  config,
  inputs,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;

  # Keep upstream's package, wrapper, dependencies and module behavior. Patch two
  # current packaging defects only:
  # 1. two env -S trampoline shebangs are not understood by Nix patchShebangs;
  # 2. the flake installPhase omits root-level QML files, although upstream's
  #    regular setup installer copies every *.qml file into the runtime.
  inirPackage = inputs.inir.packages.${system}.default.overrideAttrs (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + ''
      sed -i '1c\#!${pkgs.python3}/bin/python3' \
        scripts/hyprland/get_keybinds.py \
        scripts/colors/generate_colors_material.py
    '';

    postInstall = (oldAttrs.postInstall or "") + ''
      runtime="$out/share/quickshell/inir"
      for qml_file in ./*.qml; do
        [ -f "$qml_file" ] || continue
        install -Dm644 "$qml_file" "$runtime/$(basename "$qml_file")"
      done

      # Fail the Nix build rather than installing another unusable shell.
      test -f "$runtime/shell.qml"
      test -f "$runtime/defaults/config.json"
      test -x "$out/bin/inir"
    '';
  });
in
{
  programs.niri.enable = true;

  # The exact upstream NixOS integration: package + user service + compositor
  # wants link. Dependencies are supplied by the upstream wrapper's PATH.
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
