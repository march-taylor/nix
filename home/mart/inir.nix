{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;

  # iNiR 2.27.0 contains two executable Python helpers with an env -S shell
  # trampoline which Nix cannot patch automatically. Replace only the shebangs
  # before the normal package fixup phase.
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
  imports = [ inputs.inir.homeModules.inir ];

  programs.inir = {
    enable = true;
    package = patchedInir;
    configSymlink.enable = true;
    service.compositor = "niri";
    extraPackages = [ config.programs.niri.package ];
  };

  # iNiR ships a complete modular Niri configuration. Do not let niri-flake
  # generate a second config which would replace iNiR's binds and layer rules.
  programs.niri.config = lib.mkForce null;

  # Package-managed iNiR deliberately does not run its Arch-oriented installer.
  # Seed normal writable user files once, using the packaged defaults. Later
  # changes made from iNiR or by the user remain mutable and are not overwritten.
  home.activation.seedInirUserFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    runtime="${patchedInir}/share/quickshell/inir"
    niri_dir="${config.xdg.configHome}/niri"
    marker="$niri_dir/.seeded-from-nix-v1"

    if [ ! -e "$marker" ]; then
      timestamp="$(${pkgs.coreutils}/bin/date +%Y%m%d-%H%M%S)"
      backup_root="${config.home.homeDirectory}/inir-backup"

      if [ -e "$niri_dir" ] || [ -L "$niri_dir" ]; then
        ${pkgs.coreutils}/bin/mkdir -p "$backup_root"
        ${pkgs.coreutils}/bin/cp -a "$niri_dir" "$backup_root/niri-$timestamp"
      fi

      ${pkgs.coreutils}/bin/rm -rf "$niri_dir"
      ${pkgs.coreutils}/bin/mkdir -p "$niri_dir"
      ${pkgs.coreutils}/bin/cp -R "$runtime/defaults/niri/." "$niri_dir/"
      ${pkgs.coreutils}/bin/chmod -R u+rwX "$niri_dir"

      # Keep the requested US/Russian layout, Dolphin and the NixOS-provided
      # polkit agent while retaining the rest of iNiR's upstream defaults.
      ${pkgs.gnused}/bin/sed -i \
        's/layout "us"/layout "us,ru"\n            options "grp:win_space_toggle"/' \
        "$niri_dir/config.d/10-input-and-cursor.kdl"
      ${pkgs.gnused}/bin/sed -i \
        's/spawn "nautilus"/spawn "dolphin"/' \
        "$niri_dir/config.d/70-binds.kdl"
      ${pkgs.gnused}/bin/sed -i \
        '\#/usr/lib/mate-polkit/polkit-mate-authentication-agent-1#d' \
        "$niri_dir/config.d/50-startup.kdl"

      ${pkgs.coreutils}/bin/touch "$marker"
    fi

    state_dir="${config.xdg.stateHome}/quickshell/user"
    ${pkgs.coreutils}/bin/mkdir -p \
      "$state_dir/generated/wallpaper" \
      "$state_dir/generated/terminal" \
      "${config.xdg.cacheHome}/quickshell"
    ${pkgs.coreutils}/bin/touch "$state_dir/gamemode_active" "$state_dir/notepad.txt"
    if [ ! -e "$state_dir/todo.json" ]; then
      printf '[]\n' > "$state_dir/todo.json"
    fi
    if [ ! -e "$state_dir/notifications.json" ]; then
      printf '[]\n' > "$state_dir/notifications.json"
    fi

    user_config_dir="${config.xdg.configHome}/illogical-impulse"
    if [ ! -e "$user_config_dir/config.json" ]; then
      for candidate in \
        "$runtime/defaults/config.json" \
        "$runtime/dots/.config/illogical-impulse/config.json"
      do
        if [ -f "$candidate" ]; then
          ${pkgs.coreutils}/bin/mkdir -p "$user_config_dir"
          ${pkgs.coreutils}/bin/cp "$candidate" "$user_config_dir/config.json"
          ${pkgs.coreutils}/bin/chmod u+w "$user_config_dir/config.json"
          break
        fi
      done
    fi
  '';
}
