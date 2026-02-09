# Waybar - Wayland status bar
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  platforms = [ "linux" ];
  description = "Waybar status bar for Wayland";

  module = {
    nixosSystems.home.packages = with pkgs; [
      waybar
      # Dependencies for waybar modules
      pamixer # pulseaudio
      brightnessctl # backlight
      pavucontrol # pulseaudio on-click
    ];
  };

  dotfiles = {
    path = "waybar";
    source = "modules/home/desktop/hyprland/dotfiles/waybar";
  };
}
