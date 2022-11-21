{ config, options, pkgs, lib, ... }: with lib;
let 
  cfg = config.modules.shell.git; 
in {
  options.modules.shell.git = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.programs = {
      git = {
        enable = true;
        userName = "Damir Garifullin";
        userEmail = "gosugdr@gmail.com";
        extraConfig = {
          core.editor = "nvim";
        };
      };
    };
  };
}
