# Tier-level enable options for home modules.
# Declaring these makes "modules.home.games.enable = true" a valid option,
# enabling all modules in that category for every user (cascade via shouldEnableModule).
# Individual module enables (modules.home.games.steam.enable = true) still work.
# Used primarily by profile modules in modules/profiles/*.
#
# IMPORTANT: Only declare INTERMEDIATE tier enables here — category-level paths
# that are NOT already declared by leaf modules via mkModuleV2.
# Leaf module enables (e.g., modules.home.games.steam.enable) are declared
# by the individual modules automatically — do NOT redeclare them here.
{ lib, ... }:

let
  tier = lib.mkEnableOption;
in
{
  options.modules.home = {
    enable = tier "all home modules";

    # Top-level category tiers
    ai-tools.enable = tier "all AI-tools modules";
    browsers.enable = tier "all browser modules";
    cli.enable = tier "all CLI modules";
    desktop = {
      enable = tier "all desktop modules";
      # Sub-category tiers (no single module file covers the whole sub-dir)
      appearance.enable = tier "all appearance modules";
      services.enable = tier "all desktop service modules";
      utils.enable = tier "all desktop utility modules";
      widgets.enable = tier "all desktop widget modules";
    };
    downloads.enable = tier "all download manager modules";
    editors.enable = tier "all editor modules";
    games.enable = tier "all gaming modules";
    media.enable = tier "all media modules";
    messengers.enable = tier "all messenger modules";
    security.enable = tier "all security modules";
    shell.enable = tier "all shell modules";
    terminal.enable = tier "all terminal modules";
    utils.enable = tier "all utility modules";
    virtualisation.enable = tier "all virtualisation modules";
  };
}
