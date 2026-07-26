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
  # Force the same Qt 6 values there so Throne and other user services do not get
  # the generic qt5ct default.
  systemd.user.sessionVariables = {
    QT_QPA_PLATFORMTHEME = lib.mkForce "qt6ct";
    QT_STYLE_OVERRIDE = lib.mkForce "Darkly";
  };
}
