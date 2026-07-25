{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  inirPackage = osConfig.programs.inir.package;
  inirRuntime = "${inirPackage}/share/quickshell/inir";
  inirThemePath = lib.makeBinPath (
    [
      inirPackage
      pkgs.coreutils
      pkgs.jq
    ]
    ++ osConfig.programs.inir.extraPackages
  );
  applyInirTheme = pkgs.writeShellScript "apply-inir-theme-after-start" ''
    set -eu

    export PATH=${lib.escapeShellArg inirThemePath}

    state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/user/generated"
    ready=""

    # Reuse the persisted palette immediately on normal boots. On a fresh
    # install, wait up to one minute for iNiR to generate its first palette.
    for _ in $(${pkgs.coreutils}/bin/seq 1 120); do
      for candidate in \
        "$state_dir/app-palette.json" \
        "$state_dir/palette.json" \
        "$state_dir/colors.json"
      do
        if [ -s "$candidate" ] && ${pkgs.jq}/bin/jq empty "$candidate" >/dev/null 2>&1; then
          ready="$candidate"
          break 2
        fi
      done
      ${pkgs.coreutils}/bin/sleep 0.5
    done

    # Do not fail the whole graphical session when a first-run palette is still
    # unavailable. iNiR will apply targets itself after color generation.
    [ -n "$ready" ] || exit 0

    exec ${pkgs.coreutils}/bin/env \
      INIR_RUNTIME_DIR=${lib.escapeShellArg inirRuntime} \
      INIR_SYSTEM_RUNTIME_DIR=${lib.escapeShellArg inirRuntime} \
      INIR_FALLBACK_SYSTEM_RUNTIME_DIR=${lib.escapeShellArg inirRuntime} \
      ${inirPackage}/bin/inir theme apply all
  '';
in
{
  # Zen and Throne are started as user services after the persisted iNiR palette
  # has been applied. Starting them directly in Niri races the theme generator
  # on every login and leaves long-running applications with the default theme.
  programs.niri.settings.spawn-at-startup = lib.mkForce [
    { sh = "systemctl --user import-environment XDG_MENU_PREFIX && kbuildsycoca6"; }
    { argv = [ "wl-paste" "--type" "text" "--watch" "cliphist" "store" ]; }
    { argv = [ "wl-paste" "--type" "image" "--watch" "cliphist" "store" ]; }
    { argv = [ "steam" ]; }
    { argv = [ "AyuGram" ]; }
    { argv = [ "obsidian" ]; }
    { argv = [ "pear-desktop" ]; }
    { argv = [ "discord" ]; }
  ];

  systemd.user.services = {
    inir-theme-apply = {
      Unit = {
        Description = "Apply persisted iNiR themes to desktop applications";
        Requires = [ "inir.service" ];
        After = [ "inir.service" ];
        Before = [
          "zen-autostart.service"
          "throne-autostart.service"
        ];
        PartOf = [ "inir.service" ];
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = applyInirTheme;
      };
      Install.WantedBy = [ "niri.service" ];
    };

    zen-autostart = {
      Unit = {
        Description = "Start Zen Browser in the Niri session";
        Wants = [ "inir-theme-apply.service" ];
        After = [ "inir-theme-apply.service" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${config.home.profileDirectory}/bin/zen-browser";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install.WantedBy = [ "niri.service" ];
    };

    throne-autostart = {
      Unit = {
        Description = "Start Throne in the Niri session";
        Wants = [ "inir-theme-apply.service" ];
        After = [ "inir-theme-apply.service" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "/run/current-system/sw/bin/throne";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install.WantedBy = [ "niri.service" ];
    };
  };
}
