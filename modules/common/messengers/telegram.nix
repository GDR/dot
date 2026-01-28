{ config, options, pkgs, lib, ... }: with lib;
let
  mod = lib.my.modulePath [ "common" "messenger" "telegram" ] config;
  cfg = mod.cfg;
in
{

  options.modules.common.messenger.telegram = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      telegram-desktop
    ];
  };
}
