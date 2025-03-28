{ config, options, pkgs, lib, system, ... }: with lib;
let
  cfg = config.modules.common.virtualisation.colima;
  mkModule = lib.my.mkModule system;
in
{
  options.modules.common.virtualisation.colima = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable (mkModule {
    darwin = {
      home.packages = with pkgs; [
        colima
      ];
    };
  });
}
