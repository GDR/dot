# Cursor theme and settings
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  platforms = [ "linux" ];
  description = "Cursor theme (WhiteSur) and dconf settings utility";
  module = {
    nixosSystems.home.packages = with pkgs; [
      whitesur-cursors
      dconf
    ];
  };
}
