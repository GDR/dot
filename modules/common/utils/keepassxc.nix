{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.utils.keepassxc;
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
