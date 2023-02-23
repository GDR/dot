{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.desktop.awesomewm;
in {
  options.modules.desktop.awesomewm = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    services = {
      xserver = {
        enable = true;

        # Enable awesome wm
        windowManager.awesome = {
          enable = true;
          luaModules = [
            pkgs.luaPackages.lgi
          ];
        };

        # Enable lightdm
        displayManager = {
          defaultSession = "none+awesome";
          lightdm.enable = true;
        };
      };
    };

    user.packages = with pkgs; [
      rofi
      picom
    ];

    # Add config file for awesome wm
    home.file.".config/awesome".source = ../../dotfiles/awesome;
  };
}
