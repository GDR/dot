# Wayland-specific desktop utilities - screenshots, status bar, wallpaper
# Only enabled when Wayland compositor (hyprland) is active
{ lib, ... }:

lib.my.mkFeature {
  platforms = [ "linux" ];
  description = "Wayland-specific utilities - screenshots, status bar, wallpaper";
  homeModuleLinux = { pkgs, osConfig, lib, ... }: {
    home.packages = lib.optionals (osConfig.programs.hyprland.enable or false) (with pkgs; [
      # Screenshot utilities
      grim
      slurp
      wl-clipboard

      # Wallpaper daemon
      swww

      # Status bar
      waybar
    ]);
  };
}
