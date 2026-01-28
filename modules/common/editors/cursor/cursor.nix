{ config, options, pkgs, lib, ... }: with lib;
let
  mod = lib.my.modulePath [ "common" "editors" "cursor" ] config;
  cfg = mod.cfg;
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
