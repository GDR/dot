{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.desktop.apps.telegram;
in {
  options.modules.desktop.apps.telegram = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      # Telegram application
      tdesktop
    ];
  };
}
