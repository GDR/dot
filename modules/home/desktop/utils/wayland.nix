# Wayland-specific desktop utilities - screenshots, status bar, wallpaper
# Only enabled when Wayland compositor (hyprland) is active
{ lib, pkgs, config, ... }@args:

lib.my.mkModuleV2 args {
  platforms = [ "linux" ];
  description = "Wayland-specific utilities - screenshots, status bar, wallpaper";
  module = cfg:
    let
      # Check if Wayland is enabled system-wide
      waylandEnabled = config.systemLinux.desktop.hyprland.enable or false;
    in
    # Only enable if Wayland is enabled system-wide
    lib.mkIf waylandEnabled {
      nixosSystems.home.packages = with pkgs; [
        # Screenshot utilities
        grim
        slurp
        wl-clipboard

        # Wallpaper daemon
        swww

        # Status bar
        waybar
      ];
    };
}
