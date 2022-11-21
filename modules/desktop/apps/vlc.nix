{ config, options, pkgs, lib, ... }: with lib;
let 
  cfg = config.modules.desktop.apps.vlc; 
in {
  options.modules.desktop.apps.vlc = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      vlc
    ];
  };
}
