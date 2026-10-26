# KeePassXC password manager
{ lib, ... }:

lib.my.mkFeature {
  description = "KeePassXC password manager";
  homeModule = { pkgs, ... }: {
    home.packages = [ pkgs.keepassxc ];
  };
}
