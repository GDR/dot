{ config, options, lib, pkgs, ... }: with lib;
let
  mod = lib.my.modulePath [ "darwin" "utils" "macfuse" ] config;
  cfg = mod.cfg;
in
{

  options.modules.darwin.utils.macfuse = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      "macfuse"
    ];
  };
}
