# Brightness control
{ lib, ... }:

lib.my.mkFeature {
  platforms = [ "linux" ];
  description = "Brightness control (brightnessctl)";
  homeModuleLinux = { pkgs, ... }: {
    home.packages = [ pkgs.brightnessctl ];
  };
}
