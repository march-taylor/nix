{
  inputs,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  home.packages = [
    inputs.zen-browser.packages.${system}.default
    inputs.ayugram-desktop.packages.${system}.default
  ]
  ++ (with pkgs; [
    pear-desktop

    kdePackages.dolphin
    kdePackages.ark
    kdePackages.kio-admin
    kdePackages.kio-extras
    kdePackages.ffmpegthumbs
    kdePackages.kdegraphics-thumbnailers

    imv
    mpv
    pavucontrol
    helvum
    networkmanagerapplet

    wl-clipboard
    cliphist
    grim
    slurp
    swappy
    brightnessctl
    playerctl

    btop
    fastfetch
    ripgrep
    fd
    jq
    unzip
    zip
    p7zip
    ffmpeg
    imagemagick
    yt-dlp

    adw-gtk3
    whitesur-icon-theme
    capitaine-cursors
  ]);

  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      pull.rebase = false;
      fetch.prune = true;
    };
  };

  programs.vscodium = {
    enable = true;
    mutableExtensionsDir = true;
    profiles.default.userSettings = {
      "window.titleBarStyle" = "custom";
      "window.commandCenter" = true;
      "editor.fontFamily" = "JetBrainsMono Nerd Font";
      "editor.fontLigatures" = true;
      "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
      "telemetry.telemetryLevel" = "off";
      "update.mode" = "none";
    };
  };

  programs.keepassxc = {
    enable = true;
    autostart = true;
    settings = {
      Browser = {
        Enabled = true;
        UpdateBinaryPath = false;
      };
      FdoSecrets = {
        Enabled = true;
        ShowNotification = true;
        ConfirmDeleteItem = true;
        ConfirmAccessItem = true;
        UnlockBeforeSearch = true;
      };
      GUI = {
        ApplicationTheme = "dark";
        ShowTrayIcon = true;
        MinimizeToTray = true;
        MinimizeOnClose = true;
      };
      Security = {
        ClearClipboard = true;
        ClearClipboardTimeout = 15;
        LockDatabaseScreenLock = true;
      };
    };
  };

  # Let applications using libsecret/org.freedesktop.secrets launch KeePassXC.
  # GNOME Keyring is disabled at the NixOS level to avoid two providers racing
  # for the same DBus name.
  xdg.dataFile."dbus-1/services/org.freedesktop.secrets.service".text = ''
    [D-BUS Service]
    Name=org.freedesktop.secrets
    Exec=${pkgs.keepassxc}/bin/keepassxc
  '';

  xdg.mimeApps = {
    enable = true;
    defaultApplications."inode/directory" = [ "org.kde.dolphin.desktop" ];
  };

  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
    settings = {
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      scrollback_lines = 10000;
      wayland_titlebar_color = "system";
    };
  };

  programs.fuzzel.enable = true;
  programs.bash.enable = true;
  programs.fish.enable = true;

  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "WhiteSur-dark";
      package = pkgs.whitesur-icon-theme;
    };
    font = {
      name = "Rubik";
      size = 11;
    };
  };

  home.pointerCursor = {
    name = "capitaine-cursors-light";
    package = pkgs.capitaine-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };
}
