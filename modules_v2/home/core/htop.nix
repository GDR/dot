# htop - interactive process viewer
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  description = "htop - interactive process viewer";
  module = {
    allSystems.home.packages = [ pkgs.htop ];
  };
}
