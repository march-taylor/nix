{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;

  optionalTop = name:
    lib.optional (builtins.hasAttr name pkgs) (builtins.getAttr name pkgs);
  optionalKde = name:
    lib.optional
      (builtins.hasAttr "kdePackages" pkgs && builtins.hasAttr name pkgs.kdePackages)
      (builtins.getAttr name pkgs.kdePackages);
  optionalQt6 = name:
    lib.optional
      (builtins.hasAttr "qt6" pkgs && builtins.hasAttr name pkgs.qt6)
      (builtins.getAttr name pkgs.qt6);
  optionalPython = name:
    lib.optional
      (builtins.hasAttr name pkgs.python3Packages)
      (builtins.getAttr name pkgs.python3Packages);

  # Equivalent of upstream sdata/uv/requirements.in, built by Nix rather than
  # downloaded into a mutable per-user venv.
  inirPython = pkgs.python3.withPackages (_:
    lib.concatLists (map optionalPython [
      "click"
      "evdev"
      "kde-material-you-colors"
      "loguru"
      "material-color-utilities"
      "materialyoucolor"
      "numpy"
      "opencv4"
      "pillow"
      "psutil"
      "pycairo"
      "pygobject3"
      "tqdm"
    ]));

  # Several upstream scripts source $INIR_VENV/bin/activate before invoking
  # Python. Provide that interface while keeping the actual environment in the
  # immutable Nix store.
  inirVenv = pkgs.runCommand "inir-python-venv" { } ''
    mkdir -p "$out/bin"
    ln -s ${inirPython}/bin/python "$out/bin/python"
    ln -s ${inirPython}/bin/python3 "$out/bin/python3"
    cat > "$out/bin/activate" <<EOF
export VIRTUAL_ENV="$out"
export PATH="${inirPython}/bin:\$PATH"
EOF
  '';

  # Direct translation of the dependency bundles used by upstream's normal
  # installer. Arch-only packages such as pacman-contrib are intentionally
  # omitted; every available NixOS equivalent is exposed both system-wide and
  # in the inir.service PATH.
  inirRuntimePackages = with pkgs; [
    bash
    bc
    coreutils
    curl
    findutils
    gawk
    git
    gnugrep
    gnused
    jq
    procps
    inirPython
    ripgrep
    rsync
    systemd
    wget
    xdg-utils

    awww
    cava
    cliphist
    ddcutil
    easyeffects
    ffmpeg
    fish
    fuzzel
    go
    gowall
    grim
    gum
    imagemagick
    kitty
    libnotify
    libqalculate
    mission-center
    mpv
    networkmanager
    playerctl
    pavucontrol
    slurp
    socat
    songrec
    swayidle
    swaylock
    swappy
    tesseract
    translate-shell
    upower
    uv
    wf-recorder
    wireplumber
    wl-clipboard
    wlsunset
    wtype
    xwayland-satellite
    ydotool
  ]
  ++ optionalTop "brightnessctl"
  ++ optionalTop "geoclue2"
  ++ optionalTop "hyprpicker"
  ++ optionalKde "breeze-icons"
  ++ optionalKde "kconfig"
  ++ optionalKde "kdialog"
  ++ optionalKde "kirigami"
  ++ optionalKde "plasma-integration"
  ++ optionalKde "syntax-highlighting"
  ++ optionalKde "xembedsniproxy"
  ++ optionalTop "darkly"
  ++ optionalTop "qt6ct";

  # Quickshell must be able to resolve these imports while loading shell.qml.
  # A missing org.kde.kirigami import produces only the generic top-level error
  # "Failed to load configuration", so make both Qt 5/6 environment variable
  # names explicit instead of relying on host defaults.
  inirQmlPackages =
    optionalKde "kirigami"
    ++ optionalKde "syntax-highlighting"
    ++ optionalQt6 "qt5compat"
    ++ optionalQt6 "qtbase"
    ++ optionalQt6 "qtdeclarative"
    ++ optionalQt6 "qtimageformats"
    ++ optionalQt6 "qtmultimedia"
    ++ optionalQt6 "qtpositioning"
    ++ optionalQt6 "qtquicktimeline"
    ++ optionalQt6 "qtsensors"
    ++ optionalQt6 "qtsvg"
    ++ optionalQt6 "qttools"
    ++ optionalQt6 "qttranslations"
    ++ optionalQt6 "qtvirtualkeyboard"
    ++ optionalQt6 "qtwayland";

  inirQmlPath = lib.makeSearchPath "lib/qt-6/qml" inirQmlPackages;
  inirQtPluginPath = lib.makeSearchPath "lib/qt-6/plugins" inirQmlPackages;

  # Keep upstream's package, launcher and module behavior. Patch only current
  # packaging defects in the flake output.
  inirPackage = inputs.inir.packages.${system}.default.overrideAttrs (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + ''
      sed -i '1c\#!${pkgs.python3}/bin/python3' \
        scripts/hyprland/get_keybinds.py \
        scripts/colors/generate_colors_material.py
    '';

    postInstall = (oldAttrs.postInstall or "") + ''
      runtime="$out/share/quickshell/inir"

      # Upstream's setup installer copies the root QML entry points, while the
      # flake's runtime-root-files list currently omits them.
      for root_file in ./*.qml ./qmldir; do
        [ -f "$root_file" ] || continue
        install -Dm644 "$root_file" "$runtime/$(basename "$root_file")"
      done

      # Apply the same /usr/bin portability rewrite that upstream applies to
      # QML files copied earlier in its installPhase.
      find "$runtime" -maxdepth 1 -type f \
        \( -name '*.qml' -o -name '*.js' \) \
        -exec sed -i 's#/usr/bin/##g' {} +

      # Fail the build rather than install another incomplete shell.
      test -f "$runtime/shell.qml"
      test -f "$runtime/settings.qml"
      test -f "$runtime/defaults/config.json"
      test -d "$runtime/modules"
      test -d "$runtime/services"
      test -x "$out/bin/inir"
    '';

    postFixup = (oldAttrs.postFixup or "") + ''
      # Preserve upstream's wrapper and add the complete NixOS Qt/QML search
      # paths. QML_IMPORT_PATH is needed by some Qt 6 loaders even though the
      # older QML2_IMPORT_PATH name remains supported.
      wrapProgram "$out/bin/inir" \
        --prefix QML_IMPORT_PATH : "${inirQmlPath}" \
        --prefix QML2_IMPORT_PATH : "${inirQmlPath}" \
        --prefix QT_PLUGIN_PATH : "${inirQtPluginPath}" \
        --set-default INIR_VENV "${inirVenv}" \
        --set-default ILLOGICAL_IMPULSE_VIRTUAL_ENV "${inirVenv}"
    '';
  });
in
{
  programs.niri.enable = true;

  # Official upstream NixOS integration: package, user unit and
  # niri.service.wants/inir.service compositor wiring.
  programs.inir = {
    enable = true;
    package = inirPackage;
    service.compositor = "niri";
    extraPackages = [ config.programs.niri.package ] ++ inirRuntimePackages;
  };

  # Add the QML and Python environments to the unit as well as to the launcher
  # wrapper. The wrapper prefixes its own upstream paths, so these are additive.
  systemd.user.services.inir.environment = {
    QML_IMPORT_PATH = inirQmlPath;
    QML2_IMPORT_PATH = inirQmlPath;
    QT_PLUGIN_PATH = inirQtPluginPath;
    INIR_VENV = "${inirVenv}";
    ILLOGICAL_IMPULSE_VIRTUAL_ENV = "${inirVenv}";
  };

  environment.sessionVariables = {
    INIR_VENV = "${inirVenv}";
    ILLOGICAL_IMPULSE_VIRTUAL_ENV = "${inirVenv}";
  };

  environment.systemPackages = inirRuntimePackages;
}
