{ modulesPath, pkgs, inputs, ... }:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  networking.hostName = "nixos-installer";
  networking.networkmanager.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
    git
    vim
    nano
    just
    parted
    gptfdisk
    dosfstools
  ];

  environment.etc."nixos-template".source = inputs.self;

  system.stateVersion = "26.05";
}
