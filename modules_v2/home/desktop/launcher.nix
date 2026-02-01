# Application launcher - rofi
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  tags = [ "desktop-utils" ];
  platforms = [ "linux" ];
  description = "Application launcher (rofi)";
  module = {
    nixosSystems.home.packages = [ pkgs.rofi ];
  };
}
