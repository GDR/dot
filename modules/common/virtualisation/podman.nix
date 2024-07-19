{ config, options, lib, pkgs, ... }: with lib;
let
  cfg = config.modules.common.virtualisation.podman;
in
{
  options.modules.common.virtualisation.podman = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      podman
      vfkit
    ];
  };
}
