{ lib, ... }:
let
  btrfsOptions = [
    "compress=zstd:3"
    "noatime"
    "ssd"
    "discard=async"
  ];
in
{
  # WARNING: applying this file destroys every partition on /dev/nvme0n1.
  # The Kingston USB drive /dev/sda is intentionally not referenced here.
  disko.devices = {
    disk.main = {
      type = "disk";
      device = lib.mkDefault "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            name = "ESP";
            size = "2G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };

          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [
                "-f"
                "-L"
                "nixos"
              ];
              subvolumes = {
                "@root" = {
                  mountpoint = "/";
                  mountOptions = btrfsOptions;
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = btrfsOptions;
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = btrfsOptions;
                };
                "@log" = {
                  mountpoint = "/var/log";
                  mountOptions = btrfsOptions;
                };
                "@snapshots" = {
                  mountpoint = "/.snapshots";
                  mountOptions = btrfsOptions;
                };
              };
            };
          };
        };
      };
    };
  };
}
