{ ... }:
{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    ./removable-media.nix
    ../../modules/core
    ../../modules/hardware
    ../../modules/desktop
    ../../modules/gaming
  ];
}
