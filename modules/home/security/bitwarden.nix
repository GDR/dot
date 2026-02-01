# Bitwarden - secure password manager
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  description = "Bitwarden password manager";
  module = {
    allSystems = {
      home.packages = [ pkgs.bitwarden-desktop ];
    };
  };
}
