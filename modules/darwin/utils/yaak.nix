{ config, options, lib, pkgs, ... }: with lib;
let
  mod = lib.my.modulePath [ "darwin" "utils" "yaak" ] config;
  cfg = mod.cfg;
in
{

  options.modules.darwin.utils.yaak = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    homebrew = {
      casks = [
        "yaak"
      ];
    };
  };
}
