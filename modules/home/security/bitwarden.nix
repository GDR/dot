# Bitwarden - secure password manager
{ lib, ... }:

lib.my.mkFeature {
  description = "Bitwarden password manager";

  homeModule = { pkgs, ... }: {
    home.packages = [ pkgs.bitwarden-desktop ];
  };
}
