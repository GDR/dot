{ config, options, pkgs, lib, ... }: with lib;
let
  mod = lib.my.modulePath [ "common" "utils" "keepassxc" ] config;
  cfg = mod.cfg;
in
{

  options.modules.common.utils.keepassxc = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      keepassxc
    ];
  };
}
