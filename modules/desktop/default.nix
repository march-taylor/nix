{ config, pkgs, ... }:
{
  imports = [ ./niri.nix ];

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd ${config.programs.niri.package}/bin/niri-session";
      user = "greeter";
    };
  };

  services.dbus.enable = true;
  security.polkit.enable = true;

  # Removable media and desktop file access.
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.printing.enable = true;
  programs.dconf.enable = true;

  # GNOME Keyring is intentionally disabled. KeePassXC provides the
  # org.freedesktop.secrets service from the Home Manager configuration.
  services.gnome.gnome-keyring.enable = false;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    rubik
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  environment.systemPackages = with pkgs; [
    gparted
    ntfs3g
    exfatprogs
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
  };
}
