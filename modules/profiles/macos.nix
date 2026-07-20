# macOS system profile module — standard Darwin system setup
# Per-user enable: hostUsers.<user>.profiles.macos.enable = true
# homebrew.user and openssh.userMap are user-specific; set them directly in the host config.
{ lib, config, system, ... }:

let
  isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";

  homeModules = { };  # macOS profile has no home-manager module enables
in
{
  options.modules.profiles.macos.homeModules = lib.mkOption {
    type = lib.types.attrs;
    readOnly = true;
    internal = true;
    default = homeModules;
    description = "Home modules the macos profile enables (read by shouldEnableModule)";
  };

  config =
    let
      anyUserHasProfile = lib.any
        (u: u.profiles.macos.enable or false)
        (lib.attrValues (lib.filterAttrs (_: u: u.enable or false) config.hostUsers));
    in
    lib.mkIf anyUserHasProfile (
      lib.optionalAttrs isDarwin {
        modules.system.darwin = {
          macos-settings.enable = true;
          app-aliases.enable = true;
        };
      }
    );
}
