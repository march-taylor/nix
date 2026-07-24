{ pkgs, ... }:
{
  home.packages = with pkgs; [
    firefox
    foot
    fuzzel
    nautilus
    file-roller
    imv
    mpv
    btop
    fastfetch
    ripgrep
    fd
    jq
    unzip
    zip
  ];

  programs.git = {
    enable = true;
    settings.init.defaultBranch = "main";
  };

  programs.foot = {
    enable = true;
    settings = {
      main.font = "JetBrainsMono Nerd Font:size=11";
      scrollback.lines = 10000;
    };
  };

  programs.fuzzel.enable = true;
  programs.bash.enable = true;
  programs.fish.enable = true;
}
