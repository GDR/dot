{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.linux.awesomewm;
in
{
  options.modules.linux.awesomewm = with types; {
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
          lightdm.enable = true;
        };
      };
      displayManager.defaultSession = "none+awesome";
    };

    home.packages = with pkgs; [
      rofi
      picom
      xclip
    ];

    # Keyboard layout
    services.xserver = {
      xkb = {
        layout = "us,ru";
        variant = "";
        options = "grp:alt_space_toggle";
      };
    };

    # Add config file for awesome wm and picom
    home.file.".config/awesome".source = ./dotfiles;
    # home.file.".config/picom".source = ../../dotfiles/picom;
  };
}
