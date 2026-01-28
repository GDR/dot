{ config, options, pkgs, lib, system, ... }: with lib;
let
  mod = lib.my.modulePath [ "common" "virtualisation" "docker" ] config;
  cfg = mod.cfg;
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
        docker-credential-helpers
      ];
    };

    linux = {
      virtualisation.docker.enable = true;
      users.users.dgarifullin.extraGroups = [ "docker" ];
    };
  });
}
