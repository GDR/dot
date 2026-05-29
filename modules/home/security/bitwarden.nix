# Bitwarden - secure password manager
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  description = "Bitwarden password manager";
  module = {
    # Darwin: use Homebrew cask to avoid nixpkgs compiler-rt build chain
    darwinSystems = {
      homebrew.casks = [ "bitwarden" ];
    };

    # Linux: use nixpkgs package
    nixosSystems = {
      home.packages = [ pkgs.bitwarden-desktop ];
    };
  };
}
