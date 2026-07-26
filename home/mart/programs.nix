{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  keepassxcInitialConfig = pkgs.writeText "keepassxc-initial.ini" ''
    [Browser]
    Enabled=true
    UpdateBinaryPath=false

    [FdoSecrets]
    Enabled=true
    ShowNotification=true
    ConfirmDeleteItem=true
    ConfirmAccessItem=true
    UnlockBeforeSearch=true

    [GUI]
    ApplicationTheme=dark
    ShowTrayIcon=true
    MinimizeToTray=true
    MinimizeOnClose=true

    [Security]
    ClearClipboard=true
    ClearClipboardTimeout=15
    LockDatabaseScreenLock=true
  '';
  vscodiumInitialSettings = pkgs.writeText "vscodium-initial-settings.json" (builtins.toJSON {
    "window.titleBarStyle" = "custom";
    "window.commandCenter" = true;
    "editor.fontFamily" = "JetBrainsMono Nerd Font";
    "editor.fontLigatures" = true;
    "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
    "telemetry.telemetryLevel" = "off";
    "update.mode" = "none";
  });
in
{
  home.packages = [
    inputs.zen-browser.packages.${system}.default
    inputs.ayugram-desktop.packages.${system}.default
  ]
  ++ (with pkgs; [
    pear-desktop

    aseprite
    krita
    kdePackages.kdenlive
    element-desktop
    reaper
    codex
    uv

    # nodejs provides both `node` and `npm`.
    nodejs
    osu-lazer-bin
    obsidian
    anki-bin

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
  };

  # iNiR updates VSCodium's color theme in settings.json. Keep the initial
  # preferences reproducible, then leave the actual file writable for iNiR and
  # VSCodium instead of linking it to the read-only Nix store.
  home.activation.seedMutableVSCodiumSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings_file="${config.xdg.configHome}/VSCodium/User/settings.json"
    ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$settings_file")"

    if [ -L "$settings_file" ]; then
      tmp="$(${pkgs.coreutils}/bin/mktemp)"
      ${pkgs.coreutils}/bin/cp --dereference "$settings_file" "$tmp"
      ${pkgs.coreutils}/bin/rm -f "$settings_file"
      ${pkgs.coreutils}/bin/cp "$tmp" "$settings_file"
      ${pkgs.coreutils}/bin/rm -f "$tmp"
      ${pkgs.coreutils}/bin/chmod u+w "$settings_file"
    elif [ ! -e "$settings_file" ]; then
      ${pkgs.coreutils}/bin/cp "${vscodiumInitialSettings}" "$settings_file"
      ${pkgs.coreutils}/bin/chmod u+w "$settings_file"
    fi
  '';

  programs.keepassxc = {
    enable = true;
    autostart = true;
  };

  # Seed a normal writable config only on the first activation. Home Manager
  # does not own the file afterwards, so KeePassXC can change its settings from
  # the GUI without hitting a read-only /nix/store symlink.
  home.activation.seedKeePassXCConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    config_file="${config.xdg.configHome}/keepassxc/keepassxc.ini"
    if [ ! -e "$config_file" ]; then
      run mkdir -p "$(dirname "$config_file")"
      run cp "${keepassxcInitialConfig}" "$config_file"
      run chmod u+w "$config_file"
    fi
  '';

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
    # iNiR atomically updates current-theme.conf. Declaring the include here
    # avoids its generator trying to edit Home Manager's read-only kitty.conf.
    extraConfig = ''
      include current-theme.conf
    '';
  };

  home.activation.seedKittyThemeFile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    theme_file="${config.xdg.configHome}/kitty/current-theme.conf"
    if [ ! -e "$theme_file" ]; then
      ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$theme_file")"
      ${pkgs.coreutils}/bin/touch "$theme_file"
    fi
  '';

  # KIO/Dolphin reads these keys from kdeglobals. The iNiR KDE theme generator
  # also preserves TerminalApplication=kitty, so changing colors cannot restore
  # the xterm fallback.
  home.activation.configureDolphinTerminal = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
      --file kdeglobals --group General --key TerminalApplication kitty
    ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
      --file kdeglobals --group General --key TerminalService --delete
  '';

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
