{ ... }:
{
  # Match iNiR's own Niri defaults: plasma-integration reads the generated
  # kdeglobals colors, while Darkly provides the Qt widget style.
  home.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "kde";
    QT_STYLE_OVERRIDE = "Darkly";
  };

  # Niri-spawned applications do not reliably inherit shell startup variables,
  # so set the same values directly in the compositor environment.
  programs.niri.settings.environment = {
    QT_QPA_PLATFORMTHEME = "kde";
    QT_STYLE_OVERRIDE = "Darkly";
  };
}
