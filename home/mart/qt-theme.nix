{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Match Home Manager's Qt search path inside the user profile. Niri and
  # systemd user services need the concrete value because they do not source an
  # interactive shell before launching applications.
  qtPluginPath = lib.concatStringsSep ":" (
    map (qt: "${config.home.profileDirectory}/${qt.qtbase.qtPluginPrefix}") [
      pkgs.qt5
      pkgs.qt6
    ]
    ++ [ "/run/current-system/sw/lib/qt-6/plugins" ]
  );

  inirColorScheme = "${config.xdg.dataHome}/color-schemes/Darkly.colors";
in
{
  # plasma-integration is the Qt platform plugin that reads iNiR's live
  # kdeglobals directly. qt6ct only styles a subset of KDE applications.
  qt = {
    enable = true;
    platformTheme.name = "kde";
    style = {
      name = "darkly";
      package = pkgs.darkly;
    };
  };

  # Use KDE's platform plugin for every Qt app, including Dolphin and Prism.
  # plasma-integration is installed system-wide, so its plugin directory must
  # be retained alongside Home Manager's Qt plugin paths.
  programs.niri.settings.environment = {
    QT_QPA_PLATFORMTHEME = "kde";
    QT_STYLE_OVERRIDE = "Darkly";
    QT_PLUGIN_PATH = qtPluginPath;
  };

  home.sessionVariables = {
    QT_QPA_PLATFORMTHEME = lib.mkForce "kde";
    QT_STYLE_OVERRIDE = lib.mkForce "Darkly";
  };

  # Home Manager also exports Qt variables directly to the systemd user manager.
  # Force the same values for applications launched as transient user services.
  systemd.user.sessionVariables = {
    QT_QPA_PLATFORMTHEME = lib.mkForce "kde";
    QT_STYLE_OVERRIDE = lib.mkForce "Darkly";
  };

  # Older generations and manual experiments may have left qtct configuration
  # as a symlink into /nix/store. iNiR must be able to replace these files every
  # time its wallpaper palette changes. Convert stale links to normal writable
  # files and seed the exact contract used by apply-gtk-theme.sh.
  home.activation.prepareMutableQtctPalettes = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    for relative in qt5ct/qt5ct.conf qt6ct/qt6ct.conf; do
      file="${config.xdg.configHome}/$relative"
      dir="$(${pkgs.coreutils}/bin/dirname "$file")"
      ${pkgs.coreutils}/bin/mkdir -p "$dir"

      if [ -L "$file" ]; then
        tmp="$(${pkgs.coreutils}/bin/mktemp)"
        ${pkgs.coreutils}/bin/cp --dereference "$file" "$tmp" 2>/dev/null \
          || ${pkgs.coreutils}/bin/touch "$tmp"
        ${pkgs.coreutils}/bin/rm -f "$file"
        ${pkgs.coreutils}/bin/mv "$tmp" "$file"
      elif [ ! -e "$file" ]; then
        ${pkgs.coreutils}/bin/touch "$file"
      fi

      ${pkgs.coreutils}/bin/chmod u+w "$file"
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
        --file "$file" --group Appearance --key color_scheme_path "${inirColorScheme}"
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
        --file "$file" --group Appearance --key custom_palette true
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
        --file "$file" --group Appearance --key style Darkly
    done
  '';
}
