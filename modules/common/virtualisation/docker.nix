{ config, options, lib, pkgs, ... }: with lib;
let
  cfg = config.modules.common.virtualisation.docker;
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  options.modules.common.virtualisation.docker = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf (cfg.enable && isDarwin) {
    home.packages = with pkgs; [
      docker
    ];
  };
}
