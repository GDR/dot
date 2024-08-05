{ config, options, pkgs, lib, system, ... }: with lib;
let
  cfg = config.modules.common.virtualisation.docker;
  mkModule = lib.my.mkModule system;
in
{
  options.modules.common.virtualisation.docker = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable (mkModule {
    darwin = {
      home.packages = with pkgs; [
        docker
      ];
    };

    linux = {
      virtualisation.docker.enable = true;
      users.users.dgarifullin.extraGroups = [ "docker" ];
    };
  });
}
