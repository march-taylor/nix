{ inputs, ... }:
{
  imports = [
    inputs.nixcord.homeModules.nixcord
  ];

  programs.nixcord = {
    enable = true;
    discord = {
      enable = true;
      equicord.enable = true;
      openASAR.enable = true;
      commandLineArgs = [
        "--ozone-platform-hint=auto"
        "--enable-features=WaylandWindowDecorations,VaapiVideoDecoder"
        "--enable-wayland-ime"
      ];
      settings = {
        openasar.setup = true;
      };
    };
  };
}
