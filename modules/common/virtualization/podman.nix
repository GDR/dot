{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.virtualization.podman;
in
{
  options.modules.virtualization.podman = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    virtualisation.containers.enable = true;
    virtualisation = {
      podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };
    };

    environment.systemPackages = with pkgs; [
      dive 
      podman-tui 
      docker-compose 
    ];
  };
}
