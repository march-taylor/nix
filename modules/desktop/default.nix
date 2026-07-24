{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inirSddmTheme = pkgs.runCommand "inir-ii-pixel-sddm-theme" { } ''
    mkdir -p "$out/share/sddm/themes"
    cp -R "${inputs.inir}/dots/sddm/pixel" "$out/share/sddm/themes/ii-pixel"
  '';
in
{
  imports = [ ./niri.nix ];

  # Use the mature X11 SDDM greeter. Keep its login layout deliberately simple;
  # Niri itself provides US/Russian switching after login.
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
      options = "";
    };
  };

  services.displayManager = {
    defaultSession = "niri";
    sddm = {
      enable = true;
      wayland.enable = false;
      theme = "ii-pixel";
      extraPackages = with pkgs; [
        qt6.qt5compat
        qt6.qtdeclarative
        qt6.qtimageformats
        qt6.qtsvg
      ];
      settings.General.InputMethod = "";
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

  environment.systemPackages = [
    inirSddmTheme
  ] ++ (with pkgs; [
    gparted
    ntfs3g
    exfatprogs
  ]);

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
  };
}
