# Audio control utilities
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  tags = [ "desktop-utils" ];
  platforms = [ "linux" ];
  description = "Audio control utilities (pamixer, pavucontrol)";
  module = {
    nixosSystems.home.packages = with pkgs; [
      pamixer
      pavucontrol
    ];
  };
}
