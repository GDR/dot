{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.utils.java;
in
{
  options.modules.common.utils.java = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      jdk
    ];
  };
}
