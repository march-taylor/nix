{ ... }:
{
  programs.niri.settings = {
    environment = {
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };

    input = {
      keyboard.xkb = {
        layout = "us,ru";
        options = "grp:win_space_toggle";
      };
      touchpad = {
        tap = true;
        natural-scroll = true;
      };
    };

    prefer-no-csd = true;
    hotkey-overlay.skip-at-startup = true;

    layout = {
      gaps = 12;
      center-focused-column = "never";
      default-column-width.proportion = 0.5;
      focus-ring.enable = true;
      border.enable = false;
    };

    binds = {
      "Mod+Return".action.spawn = "kitty";
      "Mod+E".action.spawn = "dolphin";
      "Mod+D".action.spawn = "fuzzel";

      "Mod+Space" = {
        repeat = false;
        action.spawn = [
          "inir"
          "overview"
          "toggle"
        ];
      };
      "Mod+V".action.spawn = [
        "inir"
        "clipboard"
        "toggle"
      ];
      "Mod+Comma".action.spawn = [
        "inir"
        "settings"
      ];
      "Mod+Slash".action.spawn = [
        "inir"
        "cheatsheet"
        "toggle"
      ];
      "Mod+Shift+W".action.spawn = [
        "inir"
        "panelFamily"
        "cycle"
      ];
      "Mod+Alt+L" = {
        allow-when-locked = true;
        action.spawn = [
          "inir"
          "lock"
          "activate"
        ];
      };
      "Mod+Shift+S".action.spawn = [
        "inir"
        "region"
        "screenshot"
      ];
      "Mod+Shift+X".action.spawn = [
        "inir"
        "region"
        "ocr"
      ];
      "Mod+Shift+A".action.spawn = [
        "inir"
        "region"
        "search"
      ];

      "Mod+Q".action.close-window = { };
      "Mod+F".action.maximize-column = { };
      "Mod+Shift+F".action.fullscreen-window = { };

      "Mod+H".action.focus-column-left = { };
      "Mod+L".action.focus-column-right = { };
      "Mod+K".action.focus-window-up = { };
      "Mod+J".action.focus-window-down = { };

      "Mod+Shift+H".action.move-column-left = { };
      "Mod+Shift+L".action.move-column-right = { };
      "Mod+Shift+K".action.move-window-up = { };
      "Mod+Shift+J".action.move-window-down = { };

      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;

      "Mod+Shift+1".action.move-column-to-workspace = 1;
      "Mod+Shift+2".action.move-column-to-workspace = 2;
      "Mod+Shift+3".action.move-column-to-workspace = 3;
      "Mod+Shift+4".action.move-column-to-workspace = 4;
      "Mod+Shift+5".action.move-column-to-workspace = 5;

      "XF86AudioRaiseVolume" = {
        allow-when-locked = true;
        action.spawn = [
          "wpctl"
          "set-volume"
          "@DEFAULT_AUDIO_SINK@"
          "5%+"
        ];
      };
      "XF86AudioLowerVolume" = {
        allow-when-locked = true;
        action.spawn = [
          "wpctl"
          "set-volume"
          "@DEFAULT_AUDIO_SINK@"
          "5%-"
        ];
      };
      "XF86AudioMute" = {
        allow-when-locked = true;
        action.spawn = [
          "wpctl"
          "set-mute"
          "@DEFAULT_AUDIO_SINK@"
          "toggle"
        ];
      };
      "XF86MonBrightnessUp" = {
        allow-when-locked = true;
        action.spawn = [
          "brightnessctl"
          "set"
          "5%+"
        ];
      };
      "XF86MonBrightnessDown" = {
        allow-when-locked = true;
        action.spawn = [
          "brightnessctl"
          "set"
          "5%-"
        ];
      };
    };
  };
}
