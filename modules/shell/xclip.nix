{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.shell.xclip;
in {
  options.modules.shell.xclip = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [ 
      xclip
     ];
  };
}
