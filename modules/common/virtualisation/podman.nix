{ config, options, pkgs, lib, system, ... }: with lib;
let
  cfg = config.modules.common.virtualisation.podman;
  mkModule = lib.my.mkModule system;
in
{
  options.modules.common.virtualisation.podman = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable (mkModule {
    darwin = {
      home.packages = with pkgs; [
        podman
        vfkit
      ];
    };

    linux = {
      virtualisation.containers.enable = true;
      virtualisation = {
        podman = {
          enable = true;

          # Create a `docker` alias for podman, to use it as a drop-in replacement
          dockerCompat = true;

          # Required for containers under podman-compose to be able to talk to each other.
          defaultNetwork.settings.dns_enabled = true;
        };
      };
    };
  });
}
