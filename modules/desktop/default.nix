{ lib, pkgs, ... }:
{
  imports = [ ./niri.nix ];

  services.displayManager = {
    defaultSession = "niri";
    sddm = {
      enable = true;
      wayland.enable = true;
    };
  };

  services.dbus.enable = true;
  security.polkit.enable = true;

  # Removable media and desktop file access.
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.printing.enable = true;
  programs.dconf.enable = true;

  # niri-flake enables GNOME Keyring by default. Force it off so KeePassXC is
  # the only org.freedesktop.secrets provider in the user session.
  services.gnome.gnome-keyring.enable = lib.mkForce false;

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
