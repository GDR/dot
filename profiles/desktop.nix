# Desktop profile — GUI environment, browsers, media, messengers, security
# Suitable for any machine with a display manager / compositor.
{ lib, system, ... }:
{
  profileModules = {
    home.browsers.enable = lib.mkDefault true;
    # Desktop infrastructure — intentionally NOT enabling home.desktop.enable broadly
    # to avoid activating all WMs (awesomewm, hyprland). Pick a WM per host.
    home.desktop.appearance.enable = lib.mkDefault true;
    home.desktop.services.enable = lib.mkDefault true;
    home.desktop.utils.enable = lib.mkDefault true;
    home.desktop.widgets.enable = lib.mkDefault true;
    home.downloads.enable = lib.mkDefault true;
    home.media.enable = lib.mkDefault true;
    home.messengers.enable = lib.mkDefault true;
    home.security.enable = lib.mkDefault true;
    home.utils.enable = lib.mkDefault true;
  };
}
// lib.optionalAttrs (lib.hasSuffix "-linux" system) {
  modules.system.linux = {
    sound.enable = lib.mkDefault true;
    networking.networkmanager.enable = lib.mkDefault true;
    networking.tailscale.enable = lib.mkDefault true;
    networking.firewall.enable = lib.mkDefault true;
  };
}
