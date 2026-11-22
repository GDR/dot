# Notification daemon and control center — SwayNC (Athena frosted-glass layout)
{ lib, ... }:

lib.my.mkFeature {
  platforms = [ "linux" ];
  description = "Notification daemon and control center (SwayNC)";
  requires = [ "home.desktop.services.audio" ];

  homeModuleLinux =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        swaynotificationcenter
        libnotify
        # Buttons-grid quick actions (color picker, calculator, screen recorder)
        hyprpicker
        galculator
        wf-recorder
        slurp
      ];
    };

  dotfiles = {
    path = "swaync";
    source = "modules/home/desktop/services/notifications/dotfiles";
  };
}
