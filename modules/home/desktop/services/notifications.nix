# Notification daemon - dunst
{ lib, ... }:

lib.my.mkFeature {
  platforms = [ "linux" ];
  description = "Notification daemon (dunst)";
  homeModuleLinux = { pkgs, ... }: {
    home.packages = [ pkgs.dunst ];
  };
}
