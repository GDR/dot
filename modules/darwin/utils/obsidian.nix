{ config, options, lib, pkgs, ... }: with lib;
let
  mod = lib.my.modulePath [ "darwin" "utils" "obsidian" ] config;
  cfg = mod.cfg;
in
{

  options.modules.darwin.utils.obsidian = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      "obsidian"
    ];
  };
}
