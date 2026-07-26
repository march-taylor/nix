{ settings, ... }:
{
  imports = [
    ./programs.nix
    ./discord.nix
    ./niri.nix
    ./niri-fixes.nix
    ./inir.nix
    ./qt-theme.nix
    ./kitty-fixes.nix
    ./session-services.nix
    ./no-network-tray.nix
  ];

  home.username = settings.username;
  home.homeDirectory = "/home/${settings.username}";
  home.stateVersion = settings.stateVersion;

  programs.home-manager.enable = true;

  xdg = {
    enable = true;
    autostart.enable = true;
  };

  home.sessionVariables = {
    BROWSER = "zen";
    TERMINAL = "kitty";
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };
}
