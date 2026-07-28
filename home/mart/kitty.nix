{ lib, ... }:
{
  # Keep the terminal at full opacity.
  programs.niri.settings.window-rules = lib.mkAfter [
    {
      matches = [ { app-id = "^kitty$"; } ];
      opacity = 1.0;
    }
  ];

  programs.kitty.settings.inactive_text_alpha = "1.0";
}
