{
  description = "March Taylor's reproducible NixOS + Niri + iNiR system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri.url = "github:sodiboo/niri-flake";
    inir.url = "github:snowarch/iNiR";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, niri, inir, ... }:
    let
      settings = import ./settings.nix;
      inherit (settings) system username;

      mkHost = hostModule:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs settings; };
          modules = [
            hostModule
            niri.nixosModules.niri
            inir.nixosModules.inir
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "hm-backup";
              home-manager.extraSpecialArgs = { inherit inputs settings; };
              home-manager.users.${username} = import (./home + "/${username}");
            }
          ];
        };
    in {
      nixosConfigurations.desktop = mkHost ./hosts/desktop;

      packages.${system} = {
        installer-iso = self.nixosConfigurations.installer.config.system.build.isoImage;
        offline-installer-iso = self.nixosConfigurations.offline-installer.config.system.build.isoImage;
      };

      nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs settings; };
        modules = [ ./installer/iso.nix ];
      };

      nixosConfigurations.offline-installer = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs settings; };
        modules = [ ./installer/offline.nix ];
      };

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;

      checks.${system}.desktop = self.nixosConfigurations.desktop.config.system.build.toplevel;
    };
}
