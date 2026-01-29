# NetworkManager - Linux system module
{ config, pkgs, lib, ... }: with lib;

let
  cfg = config.systemLinux.networking.networkmanager;
in
{
  options.systemLinux.networking.networkmanager = {
    enable = mkEnableOption "NetworkManager for network configuration";
  };

  config = mkIf cfg.enable {
    networking.networkmanager.enable = true;
    programs.nm-applet.enable = true;
  };
}
