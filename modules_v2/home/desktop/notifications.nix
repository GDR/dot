# Notification daemon - dunst
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  platforms = [ "linux" ];
  description = "Notification daemon (dunst)";
  module = {
    nixosSystems.home.packages = [ pkgs.dunst ];
  };
}
