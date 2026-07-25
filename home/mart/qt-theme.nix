{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Match Home Manager's Qt search path inside the user profile. Niri needs the
  # concrete value because applications spawned by the compositor do not source
  # interactive shell startup files.
  qtPluginPath = lib.concatStringsSep ":" (
    map (qt: "${config.home.profileDirectory}/${qt.qtbase.qtPluginPrefix}") [
      pkgs.qt5
      pkgs.qt6
    ]
  );
in
{
  # Installing only QT_QPA_PLATFORMTHEME/QT_STYLE_OVERRIDE is insufficient on
  # NixOS: Qt applications have isolated plugin paths. The Home Manager module
  # installs both Qt 5/6 KDE integration and Breeze plugins and exposes them in
  # the profile search path. Breeze still consumes iNiR's generated kdeglobals
  # palette and ~/.local/share/color-schemes/Darkly.colors.
  qt = {
    enable = true;
    platformTheme.name = "kde";
    style.name = "breeze";
  };

  programs.niri.settings.environment = {
    QT_QPA_PLATFORMTHEME = "kde";
    QT_STYLE_OVERRIDE = "Breeze";
    QT_PLUGIN_PATH = qtPluginPath;
  };
}
