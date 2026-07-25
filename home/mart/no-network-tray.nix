{ ... }:
{
  # iNiR provides its own NetworkManager controls. Shadow the standard XDG
  # autostart entries without disabling NetworkManager itself.
  xdg.configFile = {
    "autostart/nm-applet.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=NetworkManager Applet
      Hidden=true
    '';

    "autostart/org.gnome.nm-applet.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=NetworkManager Applet
      Hidden=true
    '';
  };
}
