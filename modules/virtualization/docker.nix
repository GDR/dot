 { config, options, pkgs, lib, ... }: with lib; with lib.my;
let 
  cfg = config.modules.virtualization.docker; 
in {
  options.modules.virtualization.docker.enable = mkEnableOption "docker";

  config = mkIf cfg.enable {
    virtualisation.docker.enable = true;

    user.extraGroups = [ "docker" ];
  };
}
