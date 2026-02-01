# Raycast - Spotlight replacement and productivity launcher for macOS
{ lib, pkgs, ... }@args:
lib.my.mkModuleV2 args {
  platforms = [ "darwin" ]; # macOS only
  description = "Raycast launcher";

  module = {
    darwinSystems = {
      home.packages = [ pkgs.raycast ];
    };
  };
}

