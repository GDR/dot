{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  description = "VLC media player";
  module = {
    allSystems.home.packages = [ pkgs.vlc ];
  };
}
