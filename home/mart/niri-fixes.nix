{ lib, ... }:
{
  # This is a flag node with no arguments. `true` renders as an invalid KDL
  # argument (`honor-xdg-activation-with-invalid-serial true`).
  programs.niri.settings.debug.honor-xdg-activation-with-invalid-serial = lib.mkForce [ ];
}
