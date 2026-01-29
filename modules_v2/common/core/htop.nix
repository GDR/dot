{ config, pkgs, lib, system, _modulePath, ... }:

lib.my.mkModuleV2 {
  inherit config pkgs system _modulePath;
  tags = [ "core" ];
  description = "htop - interactive process viewer";

  module = {
    allSystems.home.packages = with pkgs; [
      htop
    ];
  };
}
