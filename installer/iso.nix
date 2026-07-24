{
  modulesPath,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  networking.hostName = "nixos-installer";
  networking.networkmanager.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  environment.systemPackages = (with pkgs; [
    git
    vim
    nano
    just
    rsync
    parted
    gptfdisk
    dosfstools
    e2fsprogs
    nvme-cli
  ]) ++ [
    inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.disko
  ];

  environment.etc."nixos-template".source = inputs.self;

  system.stateVersion = "26.05";
}
