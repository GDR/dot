{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.utils;
in
{
  options.modules.common.utils = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      bat # Fancy less replacement
    ];
  };
}
