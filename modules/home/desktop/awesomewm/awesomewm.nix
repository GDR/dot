# AwesomeWM - X11 window manager
{ lib, ... }:

lib.my.mkFeature {
  platforms = [ "linux" ];
  description = "AwesomeWM X11 window manager";
  cascade = false;

  # System-level configuration (requires root)
  nixosModule = { pkgs, ... }: {
    # XDG portal fallback for X11 apps (e.g. Lutris/Flatpak file & URI dialogs)
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.common.default = [ "gtk" ];
    };

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
  };

  # User-level configuration (routed to home-manager.users.*)
  homeModuleLinux = { pkgs, ... }: {
    home.packages = with pkgs; [
      rofi
      xclip
    ];
  };

  # Dotfiles symlink (live-editable)
  dotfiles = {
    path = "awesome";
    source = "modules/home/desktop/awesomewm/dotfiles";
  };
}
