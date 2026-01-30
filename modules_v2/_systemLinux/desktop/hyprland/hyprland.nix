# Hyprland Wayland compositor - Linux system module
{ config, pkgs, lib, self, ... }: with lib;
let
  cfg = config.systemLinux.desktop.hyprland;
in
{
  options.systemLinux.desktop.hyprland = {
    enable = mkEnableOption "Hyprland Wayland compositor";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Enable Wayland and Hyprland
      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
      };

      # Display Manager for Wayland
      services.greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
            user = "greeter";
          };
        };
      };

      # XDG portal for screen sharing and file dialogs
      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-hyprland
          xdg-desktop-portal-gtk
        ];
      };

      # Keyboard layout (for Wayland)
      services.xserver = {
        enable = mkDefault false;
        xkb = {
          layout = "us,ru";
          variant = ",mac";
          options = "grp:alt_space_toggle";
        };
      };

      # Console keyboard layout
      console.keyMap = "us";

      # Fonts for Waybar and other UI elements
      fonts.packages = with pkgs; [
        font-awesome
        nerd-fonts.jetbrains-mono
        nerd-fonts.fira-code
      ];
    }

    # Dotfiles symlink (live-editable)
    # Note: Desktop utils (rofi, waybar, dunst, etc.) moved to "desktop-utils" tag
    {
      home-manager.users = lib.my.mkDotfilesSymlink {
        inherit config self;
        path = "hypr";
        source = "modules_v2/_systemLinux/desktop/hyprland/dotfiles";
      };
    }
  ]);
}
