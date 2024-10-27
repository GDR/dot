{ config, options, lib, pkgs, ... }: with lib;
let
  cfg = config.modules.darwin.utils.obsidian;
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
