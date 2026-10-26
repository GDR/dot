# Raycast - Spotlight replacement and productivity launcher for macOS
{ lib, ... }:

lib.my.mkFeature {
  platforms = [ "darwin" ];
  description = "Raycast launcher";

  homeModuleDarwin = { pkgs, ... }: {
    home.packages = [ pkgs.raycast ];
  };
}
