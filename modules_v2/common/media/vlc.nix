{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  tags = [ "media" ];
  description = "VLC media player";
  module = {
    nixosSystems.home.packages = [ pkgs.vlc ];
    darwinSystems.homebrew.casks = [ "vlc" ];
  };
}
