{ config, options, pkgs, lib, ... }: with lib;
let 
  cfg = config.modules.desktop.apps.keepass; 
in {
  options.modules.desktop.apps.keepass = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      keepassxc
    ];
  };
}
