# Application launcher - rofi
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  platforms = [ "linux" ];
  description = "Application launcher (rofi)";
  module = {
    nixosSystems.home.packages = [ pkgs.rofi ];
  };
}
