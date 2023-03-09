{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.shell.unarchive;
in {
  options.modules.shell.unarchive = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [ 
      zip
      unzip
      rar
      gnutar
     ];
  };
}
