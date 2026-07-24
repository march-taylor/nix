{ settings, ... }:
{
  imports = [
    ./programs.nix
    ./niri.nix
  ];

  home.username = settings.username;
  home.homeDirectory = "/home/${settings.username}";
  home.stateVersion = settings.stateVersion;

  programs.home-manager.enable = true;
  xdg.enable = true;
}
