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

    home.packages = with pkgs; [
      wine
    ];
  };
}
