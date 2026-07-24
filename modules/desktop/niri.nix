{ config, pkgs, ... }:
{
  programs.niri.enable = true;

  programs.inir = {
    enable = true;
    service.compositor = "niri";
    extraPackages = [ config.programs.niri.package ];
  };

  environment.systemPackages = with pkgs; [
    xwayland-satellite
    wl-clipboard
    cliphist
    grim
    slurp
    swappy
    brightnessctl
    playerctl
    pavucontrol
    networkmanagerapplet
    libnotify
    xdg-utils
  ];
}
