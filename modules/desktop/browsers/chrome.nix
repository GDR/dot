{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.desktop.browsers.chrome;
in {
  options.modules.desktop.browsers.chrome = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      google-chrome
    ];
  };
}
