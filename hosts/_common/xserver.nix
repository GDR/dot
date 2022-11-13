{ pkgs, ... }:
{
  services.xserver = {
    enable = true;

    layout = "us,ru";
    xkbVariant = "";
    xkbOptions = "grp:alt_space_toggle";
    libinput = {
      enable = true;
      touchpad = {
        tapping = false;
      };
    };
    
    desktopManager = {
      xterm.enable = false;
    };

    windowManager.awesome = {
      enable = true;
      luaModules = [
        pkgs.luaPackages.lgi
      ];
    };
    displayManager = {
      defaultSession = "none+awesome";
      lightdm.enable = true;
    };
  };

}