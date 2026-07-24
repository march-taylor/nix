{
  pkgs,
  settings,
  ...
}:
{
  networking.hostName = settings.hostname;
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  time.timeZone = settings.timezone;
  i18n.defaultLocale = settings.locale;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    max-jobs = "auto";
    cores = 0;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nixpkgs.config.allowUnfree = true;

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.systemd.enable = true;
    tmp.cleanOnBoot = true;
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };
    kernel.sysctl = {
      "fs.inotify.max_user_watches" = 1048576;
      "vm.swappiness" = 180;
      "vm.watermark_boost_factor" = 0;
      "vm.watermark_scale_factor" = 125;
      "vm.page-cluster" = 0;
    };
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
  };

  # ext4 on NVMe only needs periodic TRIM; there are no Btrfs scrub/snapshot jobs.
  services = {
    fstrim.enable = true;
    flatpak.enable = true;
  };

  programs = {
    fish.enable = true;
    git.enable = true;
    nix-ld.enable = true;
    appimage = {
      enable = true;
      binfmt = true;
    };
  };

  users.users.${settings.username} = {
    isNormalUser = true;
    description = settings.fullName;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
      "dialout"
    ];
    shell = pkgs.fish;
  };

  security.sudo.wheelNeedsPassword = true;

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    vim
    nano
    just
    pciutils
    usbutils
    lm_sensors
    smartmontools
    nvme-cli
    e2fsprogs
    nix-output-monitor
  ];

  system.stateVersion = settings.stateVersion;
}
