# Brightness control
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  tags = [ "desktop-utils" ];
  platforms = [ "linux" ];
  description = "Brightness control (brightnessctl)";
  module = {
    nixosSystems.home.packages = [ pkgs.brightnessctl ];
  };
}
