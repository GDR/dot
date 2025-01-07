{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.utils.yandex-cloud;
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
