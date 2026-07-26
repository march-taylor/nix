{ lib, ... }:
{
  # The global Niri rule dims every inactive window to 90%. Short-lived iNiR
  # layer focus changes therefore make Kitty pulse darker even though the
  # terminal itself did not change theme. Append a Kitty-specific override.
  programs.niri.settings.window-rules = lib.mkAfter [
    {
      matches = [ { app-id = "^kitty$"; } ];
      opacity = 1.0;
    }
  ];

  # Also neutralize Kitty's own inactive-text dimming in case a generated theme
  # or a future default enables it.
  programs.kitty.settings.inactive_text_alpha = "1.0";
}
