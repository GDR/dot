{ config, options, lib, pkgs, ... }: with lib;
let
  cfg = config.modules.common.virtualisation.podman;
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  options.modules.common.virtualisation.podman = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf (cfg.enable && isDarwin) {
    home.packages = with pkgs; [
      vfkit
    ];
  };
}
