{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.shell.xbacklight;
in {
  options.modules.shell.xbacklight = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [ xorg.xbacklight ];
  };
}
