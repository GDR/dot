# htop - interactive process viewer
{ lib, ... }:

lib.my.mkFeature {
  description = "htop - interactive process viewer";
  homeModule = { pkgs, ... }: {
    home.packages = [ pkgs.htop ];
  };
}
