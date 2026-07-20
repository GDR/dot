# Desktop profile module — GUI environment, browsers, media, messengers, security
# Per-user enable: hostUsers.<user>.profiles.desktop.enable = true
{ lib, config, system, ... }:

let
  isLinux = system == "x86_64-linux" || system == "aarch64-linux";

  homeModules = {
    home.browsers.enable = true;
    # Desktop infrastructure — intentionally NOT enabling home.desktop broadly
    # to avoid activating all WMs. Pick a specific WM per host.
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
in
{
  options.modules.profiles.desktop.homeModules = lib.mkOption {
    type = lib.types.attrs;
    readOnly = true;
    internal = true;
    default = homeModules;
    description = "Home modules the desktop profile enables (read by shouldEnableModule)";
  };

  config =
    let
      anyUserHasProfile = lib.any
        (u: u.profiles.desktop.enable or false)
        (lib.attrValues (lib.filterAttrs (_: u: u.enable or false) config.hostUsers));
    in
    lib.mkIf anyUserHasProfile (
      lib.optionalAttrs isLinux {
        modules.system.linux = {
          sound.enable = true;
          networking.networkmanager.enable = true;
          networking.tailscale.enable = true;
          networking.firewall.enable = true;
        };
      }
    );
}
