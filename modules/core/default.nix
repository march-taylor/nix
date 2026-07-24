{ config, lib, pkgs, settings, ... }:
{
  networking.hostName = settings.hostname;
  networking.networkmanager.enable = true;

  time.timeZone = settings.timezone;
  i18n.defaultLocale = settings.locale;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.${settings.username} = {
    isNormalUser = true;
    description = settings.fullName;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
    shell = pkgs.fish;
  };

  programs.fish.enable = true;
  programs.git.enable = true;

  security.sudo.wheelNeedsPassword = true;

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    vim
    just
    pciutils
    usbutils
  ];

  system.stateVersion = settings.stateVersion;
}
