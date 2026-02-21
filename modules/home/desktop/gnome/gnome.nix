# GNOME desktop environment
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  platforms = [ "linux" ];
  description = "GNOME desktop environment";

  systemModule = {
    nixosSystems = {
      # X server with GDM and GNOME
      services.xserver = {
        enable = true;
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;

        # Keyboard layout
        xkb = {
          layout = "us,ru";
          variant = ",mac";
          options = "grp:alt_space_toggle";
        };
      };

      # Disable GNOME SSH agent (use system ssh-agent)
      services.gnome.gcr-ssh-agent.enable = false;

      # Console keyboard layout
      console.keyMap = "us";
    };
  };

  # User-level GNOME utilities
  module = {
    nixosSystems = {
      home.packages = with pkgs; [
        gnome-tweaks
        # gnome-utils # baobab, gucharmap, etc.
        gnome-extension-manager
      ];
    };
  };
}
