{ ... }:
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

    displayManager = {
      defaultSession = "none+awesome";
    };

    windowManager.awesome = {
      enable = true;
    };
  };

  sound.enable = true;
}