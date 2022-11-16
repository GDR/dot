{ config, options, pkgs, lib, ... }: with lib;
let 
  cfg = config.modules.desktop.touchpad; 
in {
  options.modules.desktop.touchpad = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    services.xserver = {
      libinput = {
        enable = true;
        touchpad = {
          tapping = false;
        };
      };
    };
  };
}
