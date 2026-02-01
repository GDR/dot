# AwesomeWM - X11 window manager (system-wide Linux module)
{ lib, pkgs, config, self, ... }@args:

let
  enabledUsers = lib.filterAttrs (_: u: u.enable) config.hostUsers;
in
lib.my.mkSystemModuleV2 args {
  namespace = "linux";
  description = "AwesomeWM X11 window manager";

  module = _: lib.mkMerge [
    {
      # X server with AwesomeWM
      services.xserver = {
        enable = true;

        windowManager.awesome = {
          enable = true;
          luaModules = [ pkgs.luaPackages.lgi ];
        };

        displayManager.lightdm.enable = true;

        # Keyboard layout
        xkb = {
          layout = "us,ru";
          variant = "";
          options = "grp:alt_space_toggle";
        };
      };

      services.displayManager.defaultSession = "none+awesome";

      # Picom compositor for tear-free rendering
      services.picom = {
        enable = true;
        backend = "glx";
        vSync = true;
        settings = {
          glx-no-stencil = true;
          glx-no-rebind-pixmap = true;
          use-damage = true;
          unredir-if-possible = false;
          glx-swap-method = 2;
          vsync = true;
        };
      };

      # User packages
      home-manager.users = lib.mapAttrs
        (name: _: {
          home.packages = with pkgs; [
            rofi
            xclip
          ];
        })
        enabledUsers;
    }

    # Dotfiles symlink (live-editable)
    {
      home-manager.users = lib.my.mkDotfilesSymlink {
        inherit config self;
        path = "awesome";
        source = "modules/systems/linux/desktop/awesomewm/dotfiles";
      };
    }
  ];
}
