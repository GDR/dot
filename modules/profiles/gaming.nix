# Gaming profile module — Steam, Lutris, Soundpad
# Per-user enable: hostUsers.<user>.profiles.gaming.enable = true
# Note: Steam is enabled as a system program by steam.nix when the module activates.
{ lib, config, ... }:

let
  homeModules = {
    home.games.enable = true;
  };
in
{
  options.modules.profiles.gaming.homeModules = lib.mkOption {
    type = lib.types.attrs;
    readOnly = true;
    internal = true;
    default = homeModules;
    description = "Home modules the gaming profile enables (read by shouldEnableModule)";
  };

  # No additional system config needed — Steam's systemModule handles system-level setup
  # when the home.games.steam module is activated via anyUserProfilePathEnabled.
}
