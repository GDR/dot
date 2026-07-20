# Tier-level enable options for system and profile modules.
# Declaring these makes "modules.system.all.enable = true" a valid option,
# enabling all cross-platform system modules at once (cascade).
# Individual module enables (modules.system.all.fonts.enable = true) still work.
#
# Profile enables (modules.profiles.gaming.enable = true) are declared by the
# individual profile modules in modules/profiles/; this file only holds system tiers.
{ lib, ... }: {
  options.modules.system = {
    all.enable = lib.mkEnableOption "all cross-platform system modules";
    linux.enable = lib.mkEnableOption "all Linux system modules";
    darwin.enable = lib.mkEnableOption "all Darwin system modules";
  };
}
