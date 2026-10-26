# Network manager applet
{ lib, ... }:

lib.my.mkFeature {
  platforms = [ "linux" ];
  description = "Network manager tray applet";
  homeModuleLinux = { pkgs, ... }: {
    home.packages = [ pkgs.networkmanagerapplet ];
  };
}
