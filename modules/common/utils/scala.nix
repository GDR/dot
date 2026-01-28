{ config, options, pkgs, lib, ... }: with lib;
let
  mod = lib.my.modulePath [ "common" "utils" "scala" ] config;
  cfg = mod.cfg;
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
