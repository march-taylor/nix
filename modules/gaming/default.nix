{ pkgs, ... }:
{
  programs.steam = {
    enable = true;
    protontricks.enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  environment.systemPackages = with pkgs; [
    mangohud
    goverlay
    protonup-qt
    prismlauncher
  ];
}
