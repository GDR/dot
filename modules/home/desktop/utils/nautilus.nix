# Nautilus file manager (standalone, no full GNOME desktop required)
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  platforms = [ "linux" ];
  description = "Nautilus file manager";
  module = {
    nixosSystems.home.packages = with pkgs; [
      nautilus
      # gvfs for MTP/SFTP/trash support in Nautilus
      gvfs
    ];
  };
}
