{ config, pkgs, lib, system, _modulePath, ... }:

lib.my.mkModuleV2 {
  inherit config pkgs system _modulePath;
  tags = [ "media" ];
  description = "VLC media player";
  
  module = {
    darwinSystems.homebrew.casks = [
      "vlc"
    ];

    nixosSystems.home.packages = with pkgs; [
      vlc
    ];
  };
}
