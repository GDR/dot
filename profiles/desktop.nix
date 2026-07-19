# Desktop profile — GUI environment, browsers, media, messengers, security
# Suitable for any machine with a display manager / compositor.
{
  userModules = {
    home.browsers.enable = true;
    # Desktop infrastructure — intentionally NOT enabling home.desktop.enable broadly
    # to avoid activating all WMs (awesomewm, gnome, hyprland). Pick a WM per host.
    home.desktop.appearance.enable = true;
    home.desktop.services.enable = true;
    home.desktop.utils.enable = true;
    home.desktop.widgets.enable = true;
    home.downloads.enable = true;
    home.media.enable = true;
    home.messengers.enable = true;
    home.security.enable = true;
    home.utils.enable = true;
  };

  system.linux = {
    sound.enable = true;
    networking.networkmanager.enable = true;
    networking.tailscale.enable = true;
    networking.firewall.enable = true;
  };
}
