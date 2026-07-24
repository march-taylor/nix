{ ... }:
{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    ../../modules/core
    ../../modules/hardware
    ../../modules/desktop
    ../../modules/gaming
  ];
}
