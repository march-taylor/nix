{ lib, pkgs, ... }:
let
  runtimeLibraries = [
    pkgs.libGL
    pkgs.glib
    pkgs.libxcb
    pkgs.libx11
    pkgs.libxext
    pkgs.libxcursor
    pkgs.libxfixes
    pkgs.libxi
    pkgs.libxrandr
    pkgs.libxrender
    pkgs.stdenv.cc.cc.lib
    pkgs.zlib
  ];

  comfyui = pkgs.writeShellApplication {
    name = "comfyui";
    runtimeInputs = [ pkgs.uv ];
    text = ''
      export SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt
      export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-bundle.crt
      export CURL_CA_BUNDLE=/etc/ssl/certs/ca-bundle.crt
      export LD_LIBRARY_PATH="${lib.makeLibraryPath runtimeLibraries}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

      cd /srv/apps/ComfyUI
      exec uv run main.py --enable-manager "$@"
    '';
  };
in
{
  home.packages = [ comfyui ];
}
