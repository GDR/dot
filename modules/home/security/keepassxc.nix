# KeePassXC password manager
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  description = "KeePassXC password manager";
  module = {
    allSystems = {
      home.packages = [ pkgs.keepassxc ];
    };
  };
}
