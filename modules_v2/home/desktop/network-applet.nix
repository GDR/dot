# Network manager applet
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  platforms = [ "linux" ];
  description = "Network manager tray applet";
  module = {
    nixosSystems.home.packages = [ pkgs.networkmanagerapplet ];
  };
}
