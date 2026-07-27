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
  );

  inirColorScheme = "${config.xdg.dataHome}/color-schemes/Darkly.colors";
in
{
  # iNiR writes its live palette to qt5ct/qt6ct and Darkly.colors. Using KDE +
  # Breeze here made Qt applications ignore the files that iNiR was updating.
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style = {
      name = "darkly";
      package = pkgs.darkly;
    };
  };

  # Make the Qt 6 choice explicit for applications started by Niri. Home
  # Manager's generic qtct mapping intentionally defaults to qt5ct, so override
  # it for this Qt 6 desktop.
  programs.niri.settings.environment = {
    QT_QPA_PLATFORMTHEME = "qt6ct";
    QT_STYLE_OVERRIDE = "Darkly";
    QT_PLUGIN_PATH = qtPluginPath;
  };

  home.sessionVariables = {
    QT_QPA_PLATFORMTHEME = lib.mkForce "qt6ct";
    QT_STYLE_OVERRIDE = lib.mkForce "Darkly";
  };

  # Home Manager also exports Qt variables directly to the systemd user manager.
  # Force the same Qt 6 values there so applications launched as transient user
  # services get the qt6ct palette rather than the caller's Quickshell Qt paths.
  systemd.user.sessionVariables = {
    QT_QPA_PLATFORMTHEME = lib.mkForce "qt6ct";
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
