# Spotify music streaming
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  tags = [ "media" ];
  platforms = [ "linux" "darwin" ];
  description = "Spotify music streaming client";
  module = {
    nixosSystems.home.packages = [ pkgs.spotify ];
    darwinSystems.homebrew.casks = [ "spotify" ];
  };
}
