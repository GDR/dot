{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.editors.cursor;
in
{
  options.modules.common.editors.cursor = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      code-cursor
    ];
  };
}
