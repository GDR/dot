{ config, options, pkgs, lib, ... }: with lib;
let 
  cfg = config.modules.desktop.sound; 
in {
  options.modules.desktop.sound = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    sound.enable = true;
  };
}
