 { config, options, pkgs, lib, ... }: with lib;
let 
  cfg = config.modules.virtualization.docker; 
in {
  options.modules.virtualization.docker = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    virtualisation.docker.enable = true;

    user.extraGroups = [ "docker" ];
  };
}
