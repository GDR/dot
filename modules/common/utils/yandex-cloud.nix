{ config, options, pkgs, lib, ... }: with lib;
let
  mod = lib.my.modulePath [ "common" "utils" "yandex-cloud" ] config;
  cfg = mod.cfg;
in
{

  options.modules.common.utils.yandex-cloud = with types; {
    enable = mkOption {
      default = true;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      yandex-cloud
    ];
  };
}
