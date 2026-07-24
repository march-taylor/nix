{
  config,
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  imports = [ inputs.inir.homeModules.inir ];

  # Use exactly the package configured by the NixOS iNiR module. Home Manager
  # only exposes it in the user profile and creates the traditional Quickshell
  # config symlink; the NixOS module remains the sole owner of inir.service.
  programs.inir = {
    enable = true;
    package = osConfig.programs.inir.package;
    service.enable = false;
    configSymlink.enable = true;
  };

  # `inir doctor` is designed around the mutable repo installer and may copy a
  # raw, unwrapped launcher into ~/.local/bin. Remove only that known generated
  # file so it cannot shadow the Nix wrapper and its Qt/QML environment.
  home.activation.removeDoctorInirLauncher = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    launcher="${config.home.homeDirectory}/.local/bin/inir"
    if [ -f "$launcher" ] && [ ! -L "$launcher" ] \
      && ${pkgs.gnugrep}/bin/grep -q 'Usage: inir' "$launcher" \
      && ${pkgs.gnugrep}/bin/grep -q 'cleanup-orphans' "$launcher"
    then
      ${pkgs.coreutils}/bin/rm -f "$launcher"
    fi
  '';
}
