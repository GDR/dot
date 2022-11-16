{ config, options, pkgs, lib, ... }: with lib;
let 
  cfg = config.modules.shell.htop; 
in {
  options.modules.shell.htop = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    programs = {
      htop.enable = true;
    };
  };
}
