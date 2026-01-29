# Wayland-specific desktop utilities - screenshots, status bar, wallpaper
# Only enabled when Wayland compositor (hyprland) is active
{ config, pkgs, lib, system, _modulePath, ... }: with lib;
let
  mkModule = lib.my.mkModule system;
  modulePath = _modulePath;
  moduleTags = [ "desktop-utils-wayland" ];

  pathParts = splitString "." modulePath;
  cfg = foldl (acc: part: acc.${part}) config.modules pathParts;

  # Check if Wayland is enabled system-wide
  waylandEnabled = config.systemLinux.desktop.hyprland.enable or false;
in
{
  meta = lib.my.mkModuleMeta {
    tags = moduleTags;
    platforms = [ "linux" ];
    description = "Wayland-specific utilities - screenshots, status bar, wallpaper";
  };

  options = lib.my.mkModuleOptions modulePath {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config =
    let
      shouldEnable = lib.my.shouldEnableModule { inherit config modulePath moduleTags; };
    in
    # Only enable if both tag is set AND Wayland is enabled system-wide
    mkIf (shouldEnable && waylandEnabled) (mkModule {
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
    });
}
