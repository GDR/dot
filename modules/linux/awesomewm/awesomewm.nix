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

      # Enable picom compositor for tear-free rendering
      picom = {
        enable = true;
        backend = "glx";
        vSync = true;
        settings = {
          # Performance and tearing prevention
          glx-no-stencil = true;
          glx-no-rebind-pixmap = true;
          use-damage = true;

          # Prevent tearing
          unredir-if-possible = false;

          # NVIDIA specific optimizations
          glx-swap-method = 2;

          # Vsync method
          vsync = true;
        };
      };
    };

    home.packages = with pkgs; [
      rofi
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

    # Add config file for awesome wm
    home.file.".config/awesome".source = ./dotfiles;
  };
}
