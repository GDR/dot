# Tailscale system tray indicator
{ lib, ... }:

lib.my.mkFeature {
  description = "Tailscale system tray indicator";
  platforms = [ "linux" ];
  homeModuleLinux = { pkgs, osConfig, lib, ... }: {
    home.packages = lib.optional (osConfig.services.tailscale.enable or false) pkgs.tailscale-systray;
  };
}
