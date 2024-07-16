{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.messenger.telegram;
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
