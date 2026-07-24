{ ... }:
{
  # niri-flake generates and validates ~/.config/niri/config.kdl from these
  # structured settings. iNiR itself is installed and started by its NixOS
  # module; these are the upstream launcher/overlay actions plus core Niri binds.
  programs.niri.settings = {
    environment = {
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };

    input = {
      keyboard.xkb = {
        layout = "us,ru";
        options = "grp:alt_shift_toggle";
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
      # iNiR shell overlays and launchers from upstream defaults/docs.
      "Alt+Tab".action.spawn = [
        "inir"
        "altSwitcher"
        "next"
      ];
      "Alt+Shift+Tab".action.spawn = [
        "inir"
        "altSwitcher"
        "previous"
      ];
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
      "Mod+Shift+Q".action.spawn = [
        "inir"
        "session"
        "toggle"
      ];

      # Applications. `inir terminal` uses apps.terminal from iNiR config.
      "Mod+Return".action.spawn = [
        "inir"
        "terminal"
      ];
      "Mod+T".action.spawn = [
        "inir"
        "terminal"
      ];
      "Mod+E".action.spawn = "dolphin";
      "Mod+W".action.spawn = [
        "inir"
        "browser"
      ];

      # Core Niri window management.
      "Mod+Q" = {
        repeat = false;
        action.spawn = [
          "inir"
          "close-window"
        ];
      };
      "Mod+D".action.maximize-column = { };
      "Mod+F".action.fullscreen-window = { };
      "Mod+A".action.toggle-window-floating = { };
      "Mod+R".action.switch-preset-column-width = { };
      "Mod+C".action.center-column = { };

      "Mod+H".action.focus-column-left = { };
      "Mod+L".action.focus-column-right = { };
      "Mod+K".action.focus-window-up = { };
      "Mod+J".action.focus-window-down = { };
      "Mod+Left".action.focus-column-left = { };
      "Mod+Right".action.focus-column-right = { };
      "Mod+Up".action.focus-window-up = { };
      "Mod+Down".action.focus-window-down = { };

      "Mod+Shift+H".action.move-column-left = { };
      "Mod+Shift+L".action.move-column-right = { };
      "Mod+Shift+K".action.move-window-up = { };
      "Mod+Shift+J".action.move-window-down = { };
      "Mod+Shift+Left".action.move-column-left = { };
      "Mod+Shift+Right".action.move-column-right = { };
      "Mod+Shift+Up".action.move-window-up = { };
      "Mod+Shift+Down".action.move-window-down = { };

      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+6".action.focus-workspace = 6;
      "Mod+7".action.focus-workspace = 7;
      "Mod+8".action.focus-workspace = 8;
      "Mod+9".action.focus-workspace = 9;

      "Mod+Ctrl+1".action.move-column-to-workspace = 1;
      "Mod+Ctrl+2".action.move-column-to-workspace = 2;
      "Mod+Ctrl+3".action.move-column-to-workspace = 3;
      "Mod+Ctrl+4".action.move-column-to-workspace = 4;
      "Mod+Ctrl+5".action.move-column-to-workspace = 5;
      "Mod+Ctrl+6".action.move-column-to-workspace = 6;
      "Mod+Ctrl+7".action.move-column-to-workspace = 7;
      "Mod+Ctrl+8".action.move-column-to-workspace = 8;
      "Mod+Ctrl+9".action.move-column-to-workspace = 9;

      "Print".action.screenshot = { };
      "Ctrl+Print".action.screenshot-screen = { };
      "Alt+Print".action.screenshot-window = { };

      # Hardware controls routed through iNiR for its OSD and service logic.
      "XF86AudioRaiseVolume" = {
        allow-when-locked = true;
        action.spawn = [
          "inir"
          "audio"
          "volumeUp"
        ];
      };
      "XF86AudioLowerVolume" = {
        allow-when-locked = true;
        action.spawn = [
          "inir"
          "audio"
          "volumeDown"
        ];
      };
      "XF86AudioMute" = {
        allow-when-locked = true;
        action.spawn = [
          "inir"
          "audio"
          "mute"
        ];
      };
      "XF86AudioMicMute" = {
        allow-when-locked = true;
        action.spawn = [
          "inir"
          "audio"
          "micMute"
        ];
      };
      "XF86MonBrightnessUp" = {
        allow-when-locked = true;
        action.spawn = [
          "inir"
          "brightness"
          "increment"
        ];
      };
      "XF86MonBrightnessDown" = {
        allow-when-locked = true;
        action.spawn = [
          "inir"
          "brightness"
          "decrement"
        ];
      };
      "XF86AudioPlay".action.spawn = [
        "inir"
        "mpris"
        "playPause"
      ];
      "XF86AudioPause".action.spawn = [
        "inir"
        "mpris"
        "playPause"
      ];
      "XF86AudioNext".action.spawn = [
        "inir"
        "mpris"
        "next"
      ];
      "XF86AudioPrev".action.spawn = [
        "inir"
        "mpris"
        "previous"
      ];
    };
  };
}
