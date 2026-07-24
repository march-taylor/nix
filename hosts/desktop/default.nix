{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core
    ../../modules/hardware
    ../../modules/desktop
  ];
}
