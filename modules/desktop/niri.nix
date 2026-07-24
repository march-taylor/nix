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
  # qt6ct was moved out of the top-level package set. Referring to pkgs.qt6ct
  # now intentionally throws a renamed-attribute error during Nix evaluation.
  ++ [ pkgs.qt6Packages.qt6ct ];

  upstreamInirPackage = inputs.inir.packages.${system}.default;

  # The upstream package exposes the exact runtime closure used to build its
  # bundled Quickshell. QML plugins are ABI-sensitive, so Kirigami and Qt must
  # come from this package set rather than from the host system's nixpkgs.
  upstreamInirRuntimePackages = upstreamInirPackage.passthru.runtimeDependencies or [ ];
  inirQmlPath = lib.makeSearchPath "lib/qt-6/qml" upstreamInirRuntimePackages;
  inirQtPluginPath = lib.makeSearchPath "lib/qt-6/plugins" upstreamInirRuntimePackages;

  # Keep upstream's package, launcher and module behavior. Patch only current
  # packaging defects in the flake output.
  inirPackage = upstreamInirPackage.overrideAttrs (oldAttrs: {
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
      # Preserve upstream's wrapper and add the QML/plugin paths from the exact
      # Qt stack which built Quickshell. Prefix both variable names because Qt 6
      # loaders in the wild still differ in which one they inspect.
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
    extraPackages =
      [ config.programs.niri.package ]
      ++ upstreamInirRuntimePackages
      ++ inirRuntimePackages;
  };

  # The unit receives the same ABI-matched QML paths as the launcher wrapper.
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
