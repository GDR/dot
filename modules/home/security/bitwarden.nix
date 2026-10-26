# Bitwarden - secure password manager
{ lib, ... }:

lib.my.mkFeature {
  description = "Bitwarden password manager";

  darwinModule = {
    homebrew.casks = [ "bitwarden" ];
  };

  homeModuleLinux = { pkgs, ... }: {
    home.packages = [ pkgs.bitwarden-desktop ];
  };
}
