# Lutris gaming platform - Linux only
{ lib, ... }:

lib.my.mkFeature {
  platforms = [ "linux" ];
  description = "Lutris gaming platform";

  homeModuleLinux = { pkgs, ... }: {
    programs.lutris.enable = true;
    programs.lutris.extraPackages = with pkgs; [
      gamemode
    ];

    # XDG portal for file dialogs, OpenURI (OAuth callbacks), etc.
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
      config.common.default = "gtk";
    };

    home.packages = with pkgs; [
      wine
    ];
  };
}
