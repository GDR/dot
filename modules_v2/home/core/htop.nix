# htop - interactive process viewer
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  tags = [ "core" ];
  description = "htop - interactive process viewer";
  module = {
    allSystems.home.packages = [ pkgs.htop ];
  };
}
