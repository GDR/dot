# IINA media player for macOS
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  platforms = [ "darwin" ];
  description = "IINA media player for macOS";
  module = {
    darwinSystems.home.packages = [ pkgs.iina ];
  };
}
