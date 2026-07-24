{ inputs, ... }:
{
  imports = [ ./iso.nix ];

  isoImage.storeContents = [
    inputs.self
    inputs.self.nixosConfigurations.desktop.config.system.build.toplevel
  ];
}
