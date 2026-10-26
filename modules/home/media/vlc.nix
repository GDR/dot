# VLC media player
{ lib, ... }:

lib.my.mkFeature {
  platforms = [ "linux" ];
  description = "VLC media player";
  homeModuleLinux = { pkgs, ... }: {
    home.packages = [ pkgs.vlc ];
  };
}
