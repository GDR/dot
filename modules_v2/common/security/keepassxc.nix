# KeePassXC password manager
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  tags = [ "security" ];
  description = "KeePassXC password manager";
  module = {
    nixosSystems = {
      home.packages = [ pkgs.keepassxc ];
    };
    darwinSystems = {
      homebrew.casks = [ "keepassxc" ];
    };
  };
}
