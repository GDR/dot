# IINA media player for macOS
{ lib, ... }:

lib.my.mkFeature {
  platforms = [ "darwin" ];
  description = "IINA media player for macOS";
  homeModuleDarwin = { pkgs, ... }: {
    home.packages = [ pkgs.iina ];
  };
}
