{ settings, ... }:
{
  imports = [
    ./programs.nix
    ./discord.nix
    ./niri.nix
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
