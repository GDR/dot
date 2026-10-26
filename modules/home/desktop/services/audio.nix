# Audio control utilities
{ lib, ... }:

lib.my.mkFeature {
  platforms = [ "linux" ];
  description = "Audio control utilities (pamixer, pavucontrol, pulseaudio)";
  homeModuleLinux = { pkgs, ... }: {
    home.packages = with pkgs; [
      pamixer
      pavucontrol
      pulseaudio
    ];
  };
}
