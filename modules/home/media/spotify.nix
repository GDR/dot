# Spotify music streaming
{ lib, ... }:

lib.my.mkFeature {
  description = "Spotify music streaming client";
  homeModule = { pkgs, ... }: {
    home.packages = [ pkgs.spotify ];
  };
}
