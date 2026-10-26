# GNOME desktop environment
{ lib, ... }:

lib.my.mkFeature {
  platforms = [ "linux" ];
  description = "GNOME desktop environment";

  nixosModule = {
    services = {
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;

      xserver = {
        enable = true;

        # Keyboard layout
        xkb = {
          layout = "us,ru";
          variant = ",mac";
          options = "grp:alt_space_toggle";
        };
      };
    };

    # Disable GNOME SSH agent (use system ssh-agent)
    services.gnome.gcr-ssh-agent.enable = false;

    # Console keyboard layout
    console.keyMap = "us";
  };

  homeModuleLinux = { pkgs, ... }: {
    home.packages = with pkgs; [
      gnome-tweaks
      gnome-extension-manager
    ];
  };
}
