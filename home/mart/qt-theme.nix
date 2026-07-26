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

  # Make the Qt 6 choice explicit for applications started by Niri. The generic
  # Home Manager qtct platform value is qt5ct for compatibility, while Dolphin,
  # Throne and PrismLauncher in this system are Qt 6 applications.
  programs.niri.settings.environment = {
    QT_QPA_PLATFORMTHEME = "qt6ct";
    QT_STYLE_OVERRIDE = "Darkly";
    QT_PLUGIN_PATH = qtPluginPath;
  };

  # Also expose the same values to systemd user services and terminal-launched
  # applications. The generated qt6ct.conf remains writable and owned by iNiR.
  home.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "qt6ct";
    QT_STYLE_OVERRIDE = "Darkly";
    QT_PLUGIN_PATH = qtPluginPath;
  };
}
