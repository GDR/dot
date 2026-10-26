# Cursor theme and settings
{ lib, ... }:

lib.my.mkFeature {
  platforms = [ "linux" ];
  description = "Cursor theme (WhiteSur) and dconf settings utility";
  homeModuleLinux = { pkgs, ... }: {
    home.packages = with pkgs; [
      whitesur-cursors
      dconf
    ];
  };
}
