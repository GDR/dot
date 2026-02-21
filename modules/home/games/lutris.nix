# Lutris gaming platform - Linux only
{ lib, pkgs, ... }@args: with lib;

lib.my.mkModuleV2 args {
  platforms = [ "linux" ];
  description = "Lutris gaming platform";
  requires = [ "systemLinux.graphics.nvidia" ]; # Better gaming with proper GPU drivers

  module = cfg: {
    nixosSystems = {
      programs.lutris.enable = true;
      programs.lutris = {
        extraPackages = with pkgs; [

        ];
      };

      # XDG portal for file dialogs, OpenURI (OAuth callbacks), etc.
      # Same pattern as hyprland: gtk fallback since 1.17.0 requires explicit portals.conf
      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
        config.common.default = "gtk";
      };

      home.packages = with pkgs; [
        wine
      ];
    };
  };
}
