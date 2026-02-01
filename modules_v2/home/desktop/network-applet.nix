# Network manager applet
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  tags = [ "desktop-utils" ];
  platforms = [ "linux" ];
  description = "Network manager tray applet";
  module = {
    nixosSystems.home.packages = [ pkgs.networkmanagerapplet ];
  };
}
