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

  niriConfigFragments = [
    "10-input-and-cursor.kdl"
    "20-layout-and-overview.kdl"
    "30-window-rules.kdl"
    "40-environment.kdl"
    "50-startup.kdl"
    "60-animations.kdl"
    "70-binds.kdl"
    "80-layer-rules.kdl"
    "90-user-extra.kdl"
  ];

  # Embed the upstream modular config into one file. niri-flake validates this
  # complete KDL document during the Nix build, so a broken or missing user
  # config can no longer produce a session with no usable key bindings.
  upstreamNiriConfig = lib.foldl' (
    configText: fragment:
    builtins.replaceStrings
      [ ''include "config.d/${fragment}"'' ]
      [ (builtins.readFile "${inputs.inir}/defaults/niri/config.d/${fragment}") ]
      configText
  ) (builtins.readFile "${inputs.inir}/defaults/niri/config.kdl") niriConfigFragments;

  niriConfig = builtins.replaceStrings
    [
      ''layout "us"''
      ''spawn "nautilus"''
      ''spawn-at-startup "/usr/lib/mate-polkit/polkit-mate-authentication-agent-1"''
    ]
    [
      ''
        layout "us,ru"
        options "grp:win_space_toggle"
      ''
      ''spawn "dolphin"''
      ''// Polkit prompts are handled by iNiR's built-in iiPolkit panel.''
    ]
    upstreamNiriConfig;
in
{
  imports = [ inputs.inir.homeModules.inir ];

  programs.inir = {
    enable = true;
    package = patchedInir;
    configSymlink.enable = true;
    service.compositor = "niri";
    extraPackages = [
      config.programs.niri.package
      pkgs.kitty
      pkgs.kdePackages.dolphin
      inputs.zen-browser.packages.${system}.default
    ];
  };

  # Keep the compositor-specific dependency and also make the shell start when
  # the graphical user session becomes active. Only Niri is installed here.
  systemd.user.services.inir.Install.WantedBy =
    lib.mkAfter [ "graphical-session.target" ];

  programs.niri.config = lib.mkForce niriConfig;

  # Create only mutable state and preferences. The Niri KDL itself is owned by
  # niri-flake and validated at build time.
  home.activation.prepareInirUserState = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    # Remove leftovers from the previous one-shot config seeding implementation.
    if [ -e "${config.xdg.configHome}/niri/.seeded-from-nix-v1" ]; then
      ${pkgs.coreutils}/bin/rm -rf "${config.xdg.configHome}/niri/config.d"
      ${pkgs.coreutils}/bin/rm -f "${config.xdg.configHome}/niri/.seeded-from-nix-v1"
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

    config_dir="${config.xdg.configHome}/illogical-impulse"
    config_file="$config_dir/config.json"
    ${pkgs.coreutils}/bin/mkdir -p "$config_dir"

    if [ -s "$config_file" ] && ${pkgs.jq}/bin/jq empty "$config_file" >/dev/null 2>&1; then
      tmp="$config_file.tmp"
      ${pkgs.jq}/bin/jq '
        .apps = (.apps // {})
        | .apps.terminal = "kitty"
        | .apps.browser = "zen"
        | .apps.update = "kitty -e sudo nixos-rebuild switch --flake /etc/nixos#desktop --accept-flake-config"
      ' "$config_file" > "$tmp"
      ${pkgs.coreutils}/bin/mv "$tmp" "$config_file"
    else
      cat > "$config_file" <<'EOF'
{
  "apps": {
    "terminal": "kitty",
    "browser": "zen",
    "update": "kitty -e sudo nixos-rebuild switch --flake /etc/nixos#desktop --accept-flake-config"
  }
}
EOF
    fi
    ${pkgs.coreutils}/bin/chmod u+rw "$config_file"
  '';
}
