{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  platforms = [ "linux" ];
  description = "VLC media player";
  module = {
    nixosSystems.home.packages = [ pkgs.vlc ];
  };
}
