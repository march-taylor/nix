{
  description = "Mart's reproducible NixOS + Niri + iNiR system";

  nixConfig = {
    extra-substituters = [
      "https://cache.garnix.io"
      "https://ayugram-desktop.cachix.org"
      "https://tg-owt.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "ayugram-desktop.cachix.org-1:AZ5EqHrJsAKL5YkZYLPEsb1FdD9QlypUwQ0REcJftgA="
      "tg-owt.cachix.org-1:lp0BukIhSK3EIyLcDhDZ5zABgT48nmNp6t4SnZ0wr8w="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri.url = "github:sodiboo/niri-flake";
    inir.url = "github:snowarch/iNiR";

    nixcord = {
      url = "github:4evy/nixcord";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs."nixpkgs-nixcord".follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ayugram-desktop = {
      url = "github:ndfined-crp/ayugram-desktop";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      disko,
      niri,
      inir,
      ...
    }:
    let
      settings = import ./settings.nix;
      inherit (settings) system username;

      mkHost =
        hostModule:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs settings; };
          modules = [
            hostModule
            disko.nixosModules.disko
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
    in
    {
      nixosConfigurations.desktop = mkHost ./hosts/desktop;

      packages.${system} = {
        disko = disko.packages.${system}.disko;
        disko-install = disko.packages.${system}.disko-install;
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
