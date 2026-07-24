{ ... }:
{
  # The known exFAT flash drive is mounted on first access and does not block
  # boot when it is disconnected. Other removable media remains handled by
  # UDisks/GVfs and appears through Dolphin.
  fileSystems."/mnt/orange" = {
    device = "/dev/disk/by-uuid/DDCD-5641";
    fsType = "exfat";
    options = [
      "defaults"
      "uid=1000"
      "gid=1000"
      "umask=022"
      "nofail"
      "x-systemd.automount"
      "x-systemd.device-timeout=2s"
    ];
  };
}
