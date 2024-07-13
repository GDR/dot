{ config, options, pkgs, lib, ... }: with lib;
let 
  cfg = config.modules.common.shell.tmux; 
in {
  options.modules.common.shell.tmux = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.programs = {
        tmux = {
            enable = true;
        };
    };
  };
}