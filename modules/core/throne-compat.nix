{ pkgs, ... }:
let
  # Throne 1.1.2 has severe network regressions on Linux: long-lived VLESS
  # sessions become unreliable and RTC/UDP traffic stalls. Keep the last
  # pre-1.1.2 revision that is compatible with the existing 1.1.x SQLite DB
  # and with the NixOS capability-wrapper packaging model.
  version = "1.1.1-unstable-2026-03-28";

  src = pkgs.fetchFromGitHub {
    owner = "throneproj";
    repo = "Throne";
    rev = "f53bb73790782a9a9b7bfeb30c8d6e6bcc2b05f0";
    hash = "sha256-hEjbzS0JV5OA0c9kWTFGc5kv04qzobN0TFBjMJZ1ohc=";
  };

  srsList = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/throneproj/routeprofiles/05793e2da7ca10a7acb2494f60a27ac5f7ec924c/srslist.h";
    hash = "sha256-NHer5Vy1zBL9yJlVDLVFNRG4ITzb2GTjmt718KsSrGw=";
  };

  core = pkgs.throne.passthru.core.overrideAttrs (_old: {
    inherit version src;
    vendorHash = "sha256-HNd0HI4JRPZiiSxDzOKgyAOW7tzZPCTPvOC5t+3yhoQ=";

    tags = [
      "with_clash_api"
      "with_gvisor"
      "with_quic"
      "with_wireguard"
      "with_utls"
      "with_dhcp"
      "with_tailscale"
      "badlinkname"
      "tfogo_checklinkname"
    ];
  });

  throneCompat = pkgs.throne.overrideAttrs (old: {
    inherit version src;

    preBuild = ''
      ln -s ${srsList} ./srslist.h
    '';

    passthru = old.passthru // {
      inherit core;
      goModules = core.goModules;
    };
  });
in
{
  programs.throne.package = throneCompat;
}
