# Brightness control
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  platforms = [ "linux" ];
  description = "Brightness control (brightnessctl)";
  module = {
    nixosSystems.home.packages = [ pkgs.brightnessctl ];
  };
}
