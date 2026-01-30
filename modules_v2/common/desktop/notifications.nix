# Notification daemon - dunst
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  tags = [ "desktop-utils" ];
  platforms = [ "linux" ];
  description = "Notification daemon (dunst)";
  module = {
    nixosSystems.home.packages = [ pkgs.dunst ];
  };
}
