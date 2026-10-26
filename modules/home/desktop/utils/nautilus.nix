# Nautilus file manager (standalone, no full GNOME desktop required)
{ lib, ... }:

lib.my.mkFeature {
  platforms = [ "linux" ];
  description = "Nautilus file manager";
  homeModuleLinux = { pkgs, ... }: {
    home.packages = with pkgs; [
      nautilus
      # gvfs for MTP/SFTP/trash support in Nautilus
      gvfs
    ];
  };
}
