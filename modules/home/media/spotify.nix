# Spotify music streaming
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  platforms = [ "linux" "darwin" ];
  description = "Spotify music streaming client";
  module = {
    allSystems.home.packages = [ pkgs.spotify ];
  };
}
