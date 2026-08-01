{
  config,
  lib,
  pkgs,
  ...
}:
let
  voicePreset = pkgs.writeText "voice.json" (builtins.toJSON {
    input = {
      blocklist = [ ];
      plugins_order = [ "rnnoise#0" ];
      "rnnoise#0" = {
        bypass = false;
        input-gain = 0.0;
        output-gain = 0.0;
        use-standard-model = true;
        model-name = "";
        enable-vad = false;
        vad-thres = 50.0;
        wet = 0.0;
        release = 100.0;
      };
    };
  });

  loadVoicePreset = pkgs.writeShellScript "easyeffects-load-voice-preset" ''
    set -eu

    for _ in $(${pkgs.coreutils}/bin/seq 1 100); do
      if [ -S "$XDG_RUNTIME_DIR/EasyEffectsServer" ]; then
        exec ${pkgs.easyeffects}/bin/easyeffects --load-preset Voice
      fi
      ${pkgs.coreutils}/bin/sleep 0.1
    done

    exit 1
  '';
in
{
  home.activation.configureEasyEffects = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    config_dir="${config.xdg.configHome}/easyeffects/db"
    config_file="$config_dir/easyeffectsrc"
    preset_dir="${config.xdg.dataHome}/easyeffects/input"

    ${pkgs.coreutils}/bin/mkdir -p "$config_dir" "$preset_dir"
    ${pkgs.coreutils}/bin/cp "${voicePreset}" "$preset_dir/Voice.json"
    ${pkgs.coreutils}/bin/chmod u+w "$preset_dir/Voice.json"

    ${pkgs.python3}/bin/python3 - "$config_file" <<'PY'
import configparser
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
settings = configparser.ConfigParser()
settings.optionxform = str
settings.read(path)

for section in ("Window", "Presets", "EffectsPipelines"):
    if not settings.has_section(section):
        settings.add_section(section)

settings["Window"]["enableServiceMode"] = "true"
settings["Window"]["noWindowAfterStarting"] = "true"
settings["Presets"]["lastLoadedInputPreset"] = "Voice"
settings["EffectsPipelines"]["bypass"] = "false"
settings["EffectsPipelines"]["processAllInputs"] = "true"
settings["EffectsPipelines"]["processAllOutputs"] = "false"
settings["EffectsPipelines"]["excludeMonitorStreams"] = "true"

with path.open("w") as output:
    settings.write(output)
PY
  '';

  systemd.user.services.easyeffects = {
    Unit = {
      Description = "Easy Effects microphone processing";
      Wants = [ "pipewire.service" "wireplumber.service" ];
      After = [ "pipewire.service" "wireplumber.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.easyeffects}/bin/easyeffects --service-mode --hide-window";
      ExecStartPost = loadVoicePreset;
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "niri.service" ];
  };
}
