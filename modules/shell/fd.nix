{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.shell.fd;
in {
  options.modules.shell.fd = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [ 
      fd
     ];
  };
}
