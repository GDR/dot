# Cursor theme and settings
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  tags = [ "desktop-utils" ];
  platforms = [ "linux" ];
  description = "Cursor theme (WhiteSur) and dconf settings utility";
  module = {
    nixosSystems.home.packages = with pkgs; [
      whitesur-cursors
      dconf
    ];
  };
}
