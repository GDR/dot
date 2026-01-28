{ config, options, lib, pkgs, ... }: with lib;
let
  mod = lib.my.modulePath [ "darwin" "utils" "raycast" ] config;
  cfg = mod.cfg;
in
{

  options.modules.darwin.utils.raycast = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      raycast
    ];
  };
}
