{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.laptop;
in {
  options.modules.laptop = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [ acpi ];
    programs.nm-applet.enable = true;
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
