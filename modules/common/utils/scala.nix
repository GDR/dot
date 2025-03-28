{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.utils.scala;
in
{
  options.modules.common.utils.scala = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      scala_2_13
      scalafmt
    ];
  };
}
